from __future__ import annotations

import argparse
import random
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import Base, SessionLocal, engine, run_sqlite_compat_migrations
from app.core.security import hash_password
from app.models.customer import Customer
from app.models.customer_payment import CustomerPayment
from app.models.device import Device
from app.models.expense import Expense
from app.models.product import Product
from app.models.sale import Sale, SaleItem
from app.models.sale_payment import SalePayment
from app.models.sale_refund import SaleRefund, SaleRefundItem
from app.models.stock_movement import StockMovement
from app.models.store import Store
from app.models.user import User


@dataclass(frozen=True)
class StoreTypeProfile:
    label: str
    locale: str
    product_names: list[str]
    price_range: tuple[int, int]
    cost_ratio: tuple[float, float]
    stock_range: tuple[int, int]
    low_stock_range: tuple[int, int]
    customer_names: list[str]
    daily_sale_count: tuple[int, int]
    expense_categories: list[str]


PROFILES: dict[str, StoreTypeProfile] = {
    "kirana": StoreTypeProfile(
        label="Kirana",
        locale="ne",
        product_names=[
            "Rice 1kg",
            "Rice 5kg",
            "Sunflower Oil 1L",
            "Mustard Oil 1L",
            "Sugar 1kg",
            "Salt 1kg",
            "Noodles Pack",
            "Biscuits Pack",
            "Tea 250g",
            "Soap Bar",
            "Detergent 1kg",
            "Toothpaste",
            "Mineral Water 1L",
            "Lentil 1kg",
            "Milk 1L",
        ],
        price_range=(20, 520),
        cost_ratio=(0.74, 0.92),
        stock_range=(25, 300),
        low_stock_range=(4, 20),
        customer_names=[
            "Ram",
            "Sita",
            "Hari",
            "Mina",
            "Prakash",
            "Sujan",
            "Asha",
            "Bikash",
            "Roshan",
            "Nirmala",
        ],
        daily_sale_count=(15, 40),
        expense_categories=["RENT", "TRANSPORT", "UTILITIES", "SALARY", "OTHER"],
    ),
    "pharmacy": StoreTypeProfile(
        label="Pharmacy",
        locale="en",
        product_names=[
            "Paracetamol Strip",
            "Ibuprofen Strip",
            "ORS Pack",
            "Vitamin C Bottle",
            "Bandage Roll",
            "Antacid Syrup",
            "Cough Syrup",
            "Digital Thermometer",
            "Face Mask Pack",
            "Hand Sanitizer 250ml",
            "Antibiotic Ointment",
            "Glucose Powder",
        ],
        price_range=(35, 900),
        cost_ratio=(0.62, 0.88),
        stock_range=(20, 160),
        low_stock_range=(3, 15),
        customer_names=[
            "Anil",
            "Priya",
            "Kiran",
            "Sunita",
            "Mohan",
            "Pooja",
            "Rahul",
            "Nisha",
            "Sagar",
            "Deepa",
        ],
        daily_sale_count=(10, 26),
        expense_categories=["RENT", "UTILITIES", "SALARY", "OTHER"],
    ),
    "cafe": StoreTypeProfile(
        label="Cafe",
        locale="en",
        product_names=[
            "Espresso",
            "Americano",
            "Cappuccino",
            "Latte",
            "Black Tea",
            "Lemon Tea",
            "Chicken Sandwich",
            "Veg Sandwich",
            "Muffin",
            "Brownie",
            "French Fries",
            "Cold Coffee",
        ],
        price_range=(120, 650),
        cost_ratio=(0.35, 0.58),
        stock_range=(15, 120),
        low_stock_range=(3, 12),
        customer_names=[
            "Aarav",
            "Isha",
            "Rohan",
            "Sneha",
            "Nabin",
            "Sara",
            "Avi",
            "Kriti",
            "Raj",
            "Maya",
        ],
        daily_sale_count=(25, 70),
        expense_categories=["RENT", "SALARY", "UTILITIES", "OTHER"],
    ),
    "electronics": StoreTypeProfile(
        label="Electronics",
        locale="en",
        product_names=[
            "USB Cable",
            "Fast Charger",
            "Power Bank",
            "Bluetooth Earbuds",
            "Phone Case",
            "Screen Protector",
            "HDMI Cable",
            "Wireless Mouse",
            "Keyboard",
            "Smart Watch",
            "Laptop Stand",
            "Portable Speaker",
        ],
        price_range=(180, 7800),
        cost_ratio=(0.62, 0.9),
        stock_range=(8, 80),
        low_stock_range=(2, 10),
        customer_names=[
            "Kushal",
            "Neha",
            "Vikram",
            "Aarohi",
            "Suman",
            "Priti",
            "Dinesh",
            "Jasmine",
            "Robin",
            "Bina",
        ],
        daily_sale_count=(4, 18),
        expense_categories=["RENT", "SALARY", "TRANSPORT", "OTHER"],
    ),
}


def _rand_decimal(rng: random.Random, low: int, high: int) -> Decimal:
    return Decimal(str(rng.randint(low, high))).quantize(Decimal("0.01"))


def _quantize(value: Decimal) -> Decimal:
    return value.quantize(Decimal("0.01"))


def _pick_payment_split(rng: random.Random, total: Decimal) -> tuple[str, str, list[tuple[str, Decimal]], Decimal]:
    # Returns (sale_type, payment_method, payment_lines, credit_component)
    choice = rng.random()
    if choice < 0.56:
        method = rng.choice(["CASH", "QR", "BANK"])
        return ("CASH", method, [(method, total)], Decimal("0.00"))
    if choice < 0.83:
        return ("CREDIT", "CREDIT", [("CREDIT", total)], total)

    # MIXED with split payments
    credit_part = _quantize(total * Decimal(str(rng.uniform(0.25, 0.75))))
    if credit_part <= 0:
        credit_part = Decimal("1.00")
    if credit_part >= total:
        credit_part = total - Decimal("1.00")
    non_credit = total - credit_part
    non_credit_method = rng.choice(["CASH", "QR", "BANK"])
    lines = [
        (non_credit_method, _quantize(non_credit)),
        ("CREDIT", _quantize(credit_part)),
    ]
    return ("MIXED", "MIXED", lines, _quantize(credit_part))


def _random_phone(rng: random.Random, taken: set[str]) -> str:
    while True:
        number = "98" + "".join(str(rng.randint(0, 9)) for _ in range(8))
        if number not in taken:
            taken.add(number)
            return number


def seed_store(
    db: Session,
    *,
    profile: StoreTypeProfile,
    store_index: int,
    days: int,
    rng: random.Random,
    phone_pool: set[str],
) -> dict[str, int]:
    owner_phone = _random_phone(rng, phone_pool)
    owner = User(
        phone=owner_phone,
        password_hash=hash_password("secret123"),
    )
    db.add(owner)
    db.flush()

    store = Store(
        owner_user_id=owner.id,
        name=f"{profile.label} Demo Store {store_index}",
        locale_default=profile.locale,
        currency="NPR",
        created_by=owner.id,
        updated_by=owner.id,
        device_id=f"seed-device-{profile.label.lower()}-{store_index}",
    )
    db.add(store)
    db.flush()

    db.add(
        Device(
            device_id=f"seed-{profile.label.lower()}-{store_index}-{store.id}-ios",
            owner_user_id=owner.id,
            platform="ios",
            device_model="iPhone 17 Pro Max",
            app_version="1.0.0-seed",
        )
    )
    db.add(
        Device(
            device_id=f"seed-{profile.label.lower()}-{store_index}-{store.id}-android",
            owner_user_id=owner.id,
            platform="android",
            device_model="Samsung A12",
            app_version="1.0.0-seed",
        )
    )

    products: list[Product] = []
    for name in profile.product_names:
        sell_price = _rand_decimal(rng, profile.price_range[0], profile.price_range[1])
        ratio = Decimal(str(rng.uniform(profile.cost_ratio[0], profile.cost_ratio[1])))
        cost_price = _quantize(sell_price * ratio)
        stock_qty = Decimal(rng.randint(profile.stock_range[0], profile.stock_range[1]))
        low_stock_threshold = Decimal(rng.randint(profile.low_stock_range[0], profile.low_stock_range[1]))
        product = Product(
            store_id=store.id,
            name=name,
            sell_price=sell_price,
            cost_price=cost_price,
            stock_qty=stock_qty,
            low_stock_threshold=low_stock_threshold,
            is_active=True,
            created_by=owner.id,
            updated_by=owner.id,
            device_id=f"seed-{store.id}",
        )
        db.add(product)
        products.append(product)
    db.flush()

    customers: list[Customer] = []
    for name in profile.customer_names:
        customer = Customer(
            store_id=store.id,
            name=name,
            phone=_random_phone(rng, phone_pool),
            balance=Decimal("0.00"),
            created_by=owner.id,
            updated_by=owner.id,
            device_id=f"seed-{store.id}",
            is_deleted=False,
        )
        db.add(customer)
        customers.append(customer)
    db.flush()

    sales_created = 0
    refunds_created = 0
    expenses_created = 0
    customer_payments_created = 0

    now = datetime.now(UTC)
    for day_offset in range(days):
        day = now - timedelta(days=day_offset)
        for _ in range(rng.randint(profile.daily_sale_count[0], profile.daily_sale_count[1])):
            selected = rng.sample(products, k=rng.randint(1, min(4, len(products))))
            sale_items: list[tuple[Product, Decimal, Decimal]] = []
            sale_total = Decimal("0.00")
            for product in selected:
                max_qty = int(max(1, min(6, product.stock_qty)))
                qty = Decimal(rng.randint(1, max_qty))
                unit_price = product.sell_price
                sale_items.append((product, qty, unit_price))
                sale_total += _quantize(qty * unit_price)

            if sale_total <= 0:
                continue

            sale_type, payment_method, payment_lines, credit_component = _pick_payment_split(rng, _quantize(sale_total))
            customer = rng.choice(customers) if credit_component > 0 else None

            sale = Sale(
                store_id=store.id,
                sale_type=sale_type,
                payment_method=payment_method,
                customer_id=customer.id if customer else None,
                total_amount=_quantize(sale_total),
                idempotency_key=f"seed-{store.id}-{day_offset}-{sales_created}",
                created_by=owner.id,
                updated_by=owner.id,
                device_id=f"seed-{store.id}",
                created_at=day - timedelta(minutes=rng.randint(0, 1400)),
            )
            db.add(sale)
            db.flush()

            for product, qty, unit_price in sale_items:
                line_total = _quantize(qty * unit_price)
                db.add(
                    SaleItem(
                        sale_id=sale.id,
                        product_id=product.id,
                        qty=qty,
                        unit_price=unit_price,
                        line_total=line_total,
                    )
                )
                product.stock_qty = _quantize(Decimal(product.stock_qty) - qty)
                if product.stock_qty < 0:
                    product.stock_qty = Decimal("0.00")
                product.updated_by = owner.id
                db.add(
                    StockMovement(
                        store_id=store.id,
                        product_id=product.id,
                        movement_type="SALE_DEDUCTION",
                        delta_qty=_quantize(qty * Decimal("-1")),
                        balance_after=_quantize(Decimal(product.stock_qty)),
                        reference_type="SALE",
                        reference_id=sale.id,
                        created_by=owner.id,
                        device_id=f"seed-{store.id}",
                    )
                )

            for method, amount in payment_lines:
                db.add(SalePayment(sale_id=sale.id, method=method, amount=_quantize(amount)))

            if customer is not None and credit_component > 0:
                customer.balance = _quantize(Decimal(customer.balance) + credit_component)
                customer.updated_by = owner.id
                customer.device_id = f"seed-{store.id}"

            # 12% chance partial refund
            if rng.random() < 0.12 and sale_items:
                refundable = rng.choice(sale_items)
                refund_product, sold_qty, unit_price = refundable
                refund_qty = Decimal(rng.randint(1, int(max(1, sold_qty))))
                refund_total = _quantize(refund_qty * unit_price)
                refund = SaleRefund(
                    store_id=store.id,
                    sale_id=sale.id,
                    amount=refund_total,
                    reason="Seeded customer return",
                    created_by=owner.id,
                    device_id=f"seed-{store.id}",
                    created_at=sale.created_at + timedelta(minutes=rng.randint(5, 120)),
                )
                db.add(refund)
                db.flush()
                db.add(
                    SaleRefundItem(
                        refund_id=refund.id,
                        sale_id=sale.id,
                        product_id=refund_product.id,
                        qty=refund_qty,
                        unit_price=unit_price,
                        line_total=refund_total,
                    )
                )
                refund_product.stock_qty = _quantize(Decimal(refund_product.stock_qty) + refund_qty)
                db.add(
                    StockMovement(
                        store_id=store.id,
                        product_id=refund_product.id,
                        movement_type="REFUND_RESTOCK",
                        delta_qty=refund_qty,
                        balance_after=_quantize(Decimal(refund_product.stock_qty)),
                        reference_type="SALE_REFUND",
                        reference_id=refund.id,
                        created_by=owner.id,
                        device_id=f"seed-{store.id}",
                    )
                )
                sale.total_amount = _quantize(Decimal(sale.total_amount) - refund_total)
                if sale.total_amount < 0:
                    sale.total_amount = Decimal("0.00")
                if customer is not None and credit_component > 0:
                    credit_refund = min(credit_component, refund_total)
                    customer.balance = _quantize(max(Decimal("0.00"), Decimal(customer.balance) - credit_refund))
                refunds_created += 1

            sales_created += 1

        # 1-3 expenses per day
        for _ in range(rng.randint(1, 3)):
            category = rng.choice(profile.expense_categories)
            expense_amount = _rand_decimal(rng, 200, 4000)
            db.add(
                Expense(
                    store_id=store.id,
                    category=category,
                    amount=expense_amount,
                    note=f"Seeded {category.lower()} expense",
                    created_by=owner.id,
                    updated_by=owner.id,
                    device_id=f"seed-{store.id}",
                    created_at=day - timedelta(minutes=rng.randint(0, 1439)),
                )
            )
            expenses_created += 1

    # collect payments against outstanding balances
    for customer in customers:
        balance = Decimal(customer.balance)
        if balance <= 0:
            continue
        if rng.random() < 0.62:
            amount = _quantize(balance * Decimal(str(rng.uniform(0.2, 0.95))))
            if amount <= 0:
                continue
            if amount > balance:
                amount = balance
            db.add(
                CustomerPayment(
                    store_id=store.id,
                    customer_id=customer.id,
                    method=rng.choice(["CASH", "QR", "BANK"]),
                    amount=amount,
                    note="Seeded collection",
                    created_by=owner.id,
                    device_id=f"seed-{store.id}",
                    created_at=now - timedelta(days=rng.randint(0, max(1, days - 1))),
                )
            )
            customer.balance = _quantize(balance - amount)
            customer.updated_by = owner.id
            customer_payments_created += 1

    return {
        "stores": 1,
        "users": 1,
        "products": len(products),
        "customers": len(customers),
        "sales": sales_created,
        "refunds": refunds_created,
        "customer_payments": customer_payments_created,
        "expenses": expenses_created,
        "devices": 2,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Seed realistic fake datasets for multiple store archetypes."
    )
    parser.add_argument(
        "--store-types",
        default="kirana,pharmacy,cafe,electronics",
        help="Comma-separated store types. Supported: kirana, pharmacy, cafe, electronics",
    )
    parser.add_argument(
        "--stores-per-type",
        type=int,
        default=1,
        help="How many stores to generate per store type.",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=30,
        help="How many historical days of sales/expenses to generate.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for deterministic data generation.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    types = [value.strip().lower() for value in args.store_types.split(",") if value.strip()]
    unknown = [store_type for store_type in types if store_type not in PROFILES]
    if unknown:
        raise SystemExit(f"Unknown store types: {', '.join(unknown)}")

    Base.metadata.create_all(bind=engine)
    run_sqlite_compat_migrations()

    rng = random.Random(args.seed)
    totals = {
        "stores": 0,
        "users": 0,
        "products": 0,
        "customers": 0,
        "sales": 0,
        "refunds": 0,
        "customer_payments": 0,
        "expenses": 0,
        "devices": 0,
    }

    db = SessionLocal()
    try:
        phone_pool: set[str] = set(db.scalars(select(User.phone)).all())
        for store_type in types:
            profile = PROFILES[store_type]
            for index in range(1, args.stores_per_type + 1):
                stats = seed_store(
                    db,
                    profile=profile,
                    store_index=index,
                    days=args.days,
                    rng=rng,
                    phone_pool=phone_pool,
                )
                for key, value in stats.items():
                    totals[key] += value
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

    print("Seed completed with dataset totals:")
    for key, value in totals.items():
        print(f"  {key}: {value}")
    print(f"  store_types: {', '.join(types)}")
    print(f"  stores_per_type: {args.stores_per_type}")
    print(f"  days: {args.days}")
    print(f"  seed: {args.seed}")


if __name__ == "__main__":
    main()
