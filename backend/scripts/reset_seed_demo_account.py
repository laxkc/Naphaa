from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from decimal import Decimal
import uuid

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.core.database import Base, SessionLocal, engine, run_sqlite_compat_migrations
from app.core.security import hash_password
from app.models.alert import Alert
from app.models.customer import Customer
from app.models.customer_metric import CustomerMetric
from app.models.customer_payment import CustomerPayment
from app.models.device import Device
from app.models.expense import Expense
from app.models.product import Product
from app.models.revoked_token import RevokedToken
from app.models.sale import Sale, SaleItem
from app.models.sale_payment import SalePayment
from app.models.sale_refund import SaleRefund, SaleRefundItem
from app.models.stock_movement import StockMovement
from app.models.store import Store
from app.models.sync_event import SyncEvent
from app.models.user import User
from app.services.intelligence_service import IntelligenceService
from app.services.ledger_service import LedgerService
from app.services.sync_event_service import SyncEventService


DEMO_PHONE = "9800000999"
DEMO_PASSWORD = "demoPass123"
DEMO_STORE_NAME = "Demo Store"
DEMO_LOCALE = "ne"
DEMO_CURRENCY = "NPR"
DEMO_DEVICE_ID = "demo-seed-device-9800000999"
NS = uuid.UUID("b36f9325-7065-4c8a-a721-158eedf13aaa")


def sid(key: str) -> str:
    return str(uuid.uuid5(NS, key))


def dec(v: int | float | str) -> Decimal:
    return Decimal(str(v))


@dataclass(frozen=True)
class ProductSeed:
    key: str
    name: str
    sell_price: Decimal
    cost_price: Decimal
    opening_stock: Decimal
    low_stock_threshold: Decimal


@dataclass(frozen=True)
class CustomerSeed:
    key: str
    name: str
    phone: str | None


PRODUCTS = [
    ProductSeed("rice_1kg", "Rice 1kg", dec(120), dec(92), dec(40), dec(10)),
    ProductSeed("oil_1l", "Sunflower Oil 1L", dec(350), dec(300), dec(18), dec(6)),
    ProductSeed("sugar_1kg", "Sugar 1kg", dec(90), dec(72), dec(14), dec(8)),
    ProductSeed("noodles", "Noodles Pack", dec(30), dec(22), dec(120), dec(20)),
    ProductSeed("biscuits", "Biscuits Pack", dec(25), dec(18), dec(70), dec(15)),
    ProductSeed("tea_250g", "Tea 250g", dec(140), dec(110), dec(25), dec(6)),
    ProductSeed("soap", "Soap Bar", dec(45), dec(32), dec(55), dec(10)),
    ProductSeed("milk_1l", "Milk 1L", dec(110), dec(92), dec(12), dec(5)),
    ProductSeed("soft_drink", "Soft Drink 1.5L", dec(155), dec(125), dec(40), dec(8)),
    ProductSeed("detergent", "Detergent 1kg", dec(230), dec(185), dec(14), dec(4)),
    ProductSeed("salt_1kg", "Salt 1kg", dec(35), dec(24), dec(30), dec(8)),
    ProductSeed("lentil_1kg", "Lentil 1kg", dec(180), dec(150), dec(16), dec(5)),
]

CUSTOMERS = [
    CustomerSeed("ram", "Ram", "9800000001"),
    CustomerSeed("sita", "Sita", "9800000002"),
    CustomerSeed("gopal", "Gopal", "9800000003"),
    CustomerSeed("rohan", "Rohan", "9800000004"),
    CustomerSeed("mina", "Mina", "9800000005"),
    CustomerSeed("hari", "Hari", None),
]


def _dt(days_ago: int, hour: int, minute: int = 0) -> datetime:
    now = datetime.now(UTC)
    base = (now - timedelta(days=days_ago)).replace(
        hour=hour,
        minute=minute,
        second=0,
        microsecond=0,
    )
    return base


def _delete_store_data(db: Session, store_id: str) -> dict[str, int]:
    sale_ids = [r for r in db.scalars(select(Sale.id).where(Sale.store_id == store_id)).all()]
    product_ids = [r for r in db.scalars(select(Product.id).where(Product.store_id == store_id)).all()]

    deleted: dict[str, int] = {}

    refund_ids = [
        r for r in db.scalars(select(SaleRefund.id).where(SaleRefund.store_id == store_id)).all()
    ]
    if refund_ids:
        deleted["sale_refund_items"] = db.execute(
            delete(SaleRefundItem).where(SaleRefundItem.refund_id.in_(refund_ids))
        ).rowcount or 0
    deleted["sale_refunds"] = db.execute(
        delete(SaleRefund).where(SaleRefund.store_id == store_id)
    ).rowcount or 0

    if sale_ids:
        deleted["sale_payments"] = db.execute(
            delete(SalePayment).where(SalePayment.sale_id.in_(sale_ids))
        ).rowcount or 0
        deleted["sale_items"] = db.execute(
            delete(SaleItem).where(SaleItem.sale_id.in_(sale_ids))
        ).rowcount or 0
    deleted["sales"] = db.execute(delete(Sale).where(Sale.store_id == store_id)).rowcount or 0

    deleted["stock_movements"] = db.execute(
        delete(StockMovement).where(StockMovement.store_id == store_id)
    ).rowcount or 0
    deleted["customer_payments"] = db.execute(
        delete(CustomerPayment).where(CustomerPayment.store_id == store_id)
    ).rowcount or 0
    deleted["customer_metrics"] = db.execute(
        delete(CustomerMetric).where(CustomerMetric.store_id == store_id)
    ).rowcount or 0
    deleted["alerts"] = db.execute(delete(Alert).where(Alert.store_id == store_id)).rowcount or 0
    deleted["ledger_entries"] = db.execute(
        delete(__import__("app.models.ledger_entry", fromlist=["LedgerEntry"]).LedgerEntry).where(
            __import__("app.models.ledger_entry", fromlist=["LedgerEntry"]).LedgerEntry.store_id == store_id
        )
    ).rowcount or 0
    deleted["sync_events"] = db.execute(
        delete(SyncEvent).where(SyncEvent.store_id == store_id)
    ).rowcount or 0
    deleted["expenses"] = db.execute(
        delete(Expense).where(Expense.store_id == store_id)
    ).rowcount or 0
    deleted["customers"] = db.execute(
        delete(Customer).where(Customer.store_id == store_id)
    ).rowcount or 0
    deleted["products"] = db.execute(
        delete(Product).where(Product.store_id == store_id)
    ).rowcount or 0
    return deleted


def reset_demo_account(db: Session, *, phone: str = DEMO_PHONE) -> dict[str, int]:
    user = db.scalar(select(User).where(User.phone == phone))
    if user is None:
        return {}

    deleted: dict[str, int] = {}
    stores = db.scalars(select(Store).where(Store.owner_user_id == user.id)).all()
    for store in stores:
        store_deleted = _delete_store_data(db, store.id)
        for k, v in store_deleted.items():
            deleted[k] = deleted.get(k, 0) + v
    deleted["devices"] = db.execute(
        delete(Device).where(Device.owner_user_id == user.id)
    ).rowcount or 0

    # `revoked_tokens` has no direct user FK; keep global history intact by default.
    deleted["stores"] = db.execute(
        delete(Store).where(Store.owner_user_id == user.id)
    ).rowcount or 0
    db.delete(user)
    deleted["users"] = 1
    db.flush()
    return deleted


def ensure_demo_user_store(
    db: Session,
    *,
    phone: str = DEMO_PHONE,
    password: str = DEMO_PASSWORD,
) -> tuple[User, Store]:
    user = User(
        id=sid("user"),
        phone=phone,
        password_hash=hash_password(password),
        role="owner",
    )
    store = Store(
        id=sid("store"),
        owner_user_id=user.id,
        name=DEMO_STORE_NAME,
        locale_default=DEMO_LOCALE,
        currency=DEMO_CURRENCY,
        created_by=user.id,
        updated_by=user.id,
        device_id=DEMO_DEVICE_ID,
    )
    db.add(user)
    db.add(store)
    db.flush()
    db.add(
        Device(
            device_id=DEMO_DEVICE_ID,
            owner_user_id=user.id,
            platform="ios",
            device_model="iPhone Simulator",
            app_version="1.0.0-demo-seed",
        )
    )
    db.flush()
    return user, store


def _create_products(db: Session, *, store: Store, user: User) -> dict[str, Product]:
    now = datetime.now(UTC)
    products: dict[str, Product] = {}
    for item in PRODUCTS:
        p = Product(
            id=sid(f"product:{item.key}"),
            store_id=store.id,
            name=item.name,
            sell_price=item.sell_price,
            cost_price=item.cost_price,
            stock_qty=item.opening_stock,
            low_stock_threshold=item.low_stock_threshold,
            is_active=True,
            is_deleted=False,
            created_by=user.id,
            updated_by=user.id,
            device_id=DEMO_DEVICE_ID,
            created_at=now,
            updated_at=now,
        )
        db.add(p)
        products[item.key] = p
    db.flush()
    for p in products.values():
        SyncEventService.emit(
            db,
            store_id=store.id,
            entity="product",
            operation="UPSERT",
            payload=SyncEventService.product_payload(p),
        )
    return products


def _create_customers(db: Session, *, store: Store, user: User) -> dict[str, Customer]:
    now = datetime.now(UTC)
    customers: dict[str, Customer] = {}
    for item in CUSTOMERS:
        c = Customer(
            id=sid(f"customer:{item.key}"),
            store_id=store.id,
            name=item.name,
            phone=item.phone,
            balance=Decimal("0"),
            is_deleted=False,
            created_by=user.id,
            updated_by=user.id,
            device_id=DEMO_DEVICE_ID,
            created_at=now,
            updated_at=now,
        )
        db.add(c)
        customers[item.key] = c
    db.flush()
    for c in customers.values():
        SyncEventService.emit(
            db,
            store_id=store.id,
            entity="customer",
            operation="UPSERT",
            payload=SyncEventService.customer_payload(c),
        )
    return customers


def _add_expense(
    db: Session,
    *,
    store: Store,
    user: User,
    category: str,
    amount: Decimal,
    note: str,
    created_at: datetime,
) -> Expense:
    expense = Expense(
        id=sid(f"expense:{note}:{created_at.isoformat()}"),
        store_id=store.id,
        category=category,
        amount=amount,
        note=note,
        created_by=user.id,
        updated_by=user.id,
        device_id=DEMO_DEVICE_ID,
        created_at=created_at,
    )
    db.add(expense)
    db.flush()
    LedgerService.record_expense(db, expense)
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="expense",
        operation="UPSERT",
        payload=SyncEventService.expense_payload(expense),
    )
    return expense


def _add_sale(
    db: Session,
    *,
    store: Store,
    user: User,
    products: dict[str, Product],
    customer: Customer | None,
    created_at: datetime,
    items: list[tuple[str, Decimal]],
    sale_type: str = "CASH",
    split_methods: list[tuple[str, Decimal]] | None = None,
    note_key: str = "",
) -> Sale:
    sale_id = sid(f"sale:{note_key}:{created_at.isoformat()}")
    sale_items: list[SaleItem] = []
    total = Decimal("0")

    for pkey, qty in items:
        product = products[pkey]
        unit_price = Decimal(product.sell_price)
        line_total = (qty * unit_price).quantize(Decimal("0.01"))
        total += line_total
        sale_items.append(
            SaleItem(
                id=sid(f"sale_item:{sale_id}:{pkey}"),
                sale_id=sale_id,
                product_id=product.id,
                qty=qty,
                unit_price=unit_price,
                line_total=line_total,
            )
        )

    payment_method = sale_type if sale_type in {"CASH", "CREDIT"} else "CASH"
    sale = Sale(
        id=sale_id,
        store_id=store.id,
        sale_type=sale_type,
        payment_method=payment_method,
        customer_id=customer.id if customer else None,
        total_amount=total.quantize(Decimal("0.01")),
        idempotency_key=f"demo-{sale_id}",
        created_by=user.id,
        updated_by=user.id,
        device_id=DEMO_DEVICE_ID,
        created_at=created_at,
        updated_at=created_at,
    )
    db.add(sale)
    db.flush()

    for si in sale_items:
        db.add(si)
        product = db.get(Product, si.product_id)
        assert product is not None
        product.stock_qty = (Decimal(product.stock_qty) - Decimal(si.qty)).quantize(Decimal("0.01"))
        product.updated_at = created_at
        db.add(
            StockMovement(
                id=sid(f"stock_move:sale:{sale.id}:{si.product_id}"),
                store_id=store.id,
                product_id=si.product_id,
                movement_type="SALE",
                delta_qty=(Decimal("0") - Decimal(si.qty)).quantize(Decimal("0.01")),
                balance_after=Decimal(product.stock_qty),
                reason="Seed sale",
                reference_type="sale",
                reference_id=sale.id,
                created_by=user.id,
                device_id=DEMO_DEVICE_ID,
                created_at=created_at,
            )
        )

    payments = split_methods or (
        [("CREDIT", total)] if sale_type == "CREDIT" else [("CASH", total)]
    )
    credit_component = Decimal("0")
    for idx, (method, amount) in enumerate(payments):
        amount = Decimal(amount).quantize(Decimal("0.01"))
        db.add(
            SalePayment(
                id=sid(f"sale_payment:{sale.id}:{idx}:{method}"),
                sale_id=sale.id,
                method=method,
                amount=amount,
                created_at=created_at,
            )
        )
        if method.upper() == "CREDIT":
            credit_component += amount

    if customer is not None and credit_component > 0:
        customer.balance = (Decimal(customer.balance) + credit_component).quantize(Decimal("0.01"))
        customer.updated_at = created_at

    db.flush()
    LedgerService.record_sale(db, sale, credit_component=credit_component)
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="sale",
        operation="UPSERT",
        payload=SyncEventService.sale_payload(sale),
    )
    return sale


def _add_customer_payment(
    db: Session,
    *,
    store: Store,
    user: User,
    customer: Customer,
    amount: Decimal,
    created_at: datetime,
    method: str = "CASH",
    note: str = "Credit payment",
) -> CustomerPayment:
    payment = CustomerPayment(
        id=sid(f"customer_payment:{customer.id}:{created_at.isoformat()}:{amount}"),
        store_id=store.id,
        customer_id=customer.id,
        method=method,
        amount=amount.quantize(Decimal("0.01")),
        note=note,
        created_by=user.id,
        device_id=DEMO_DEVICE_ID,
        created_at=created_at,
    )
    db.add(payment)
    customer.balance = max(
        Decimal("0"),
        (Decimal(customer.balance) - Decimal(payment.amount)).quantize(Decimal("0.01")),
    )
    customer.updated_at = created_at
    db.flush()
    LedgerService.record_customer_payment(db, payment)
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="customer_payment",
        operation="UPSERT",
        payload=SyncEventService.customer_payment_payload(payment),
    )
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="customer",
        operation="UPSERT",
        payload=SyncEventService.customer_payload(customer),
    )
    return payment


def seed_demo_data(db: Session, *, user: User, store: Store) -> dict[str, int]:
    products = _create_products(db, store=store, user=user)
    customers = _create_customers(db, store=store, user=user)

    # Recurring expenses over prior weeks + one spike this week (transport).
    for weeks_ago in (4, 3, 2, 1):
        _add_expense(
            db,
            store=store,
            user=user,
            category="TRANSPORT",
            amount=dec(250),
            note=f"Transport week-{weeks_ago}",
            created_at=_dt(weeks_ago * 7, 11),
        )
    _add_expense(
        db,
        store=store,
        user=user,
        category="TRANSPORT",
        amount=dec(1800),
        note="Transport spike this week",
        created_at=_dt(1, 13),
    )
    _add_expense(
        db,
        store=store,
        user=user,
        category="RENT",
        amount=dec(12000),
        note="Shop rent",
        created_at=_dt(20, 9),
    )
    _add_expense(
        db,
        store=store,
        user=user,
        category="UTILITIES",
        amount=dec(2400),
        note="Electricity",
        created_at=_dt(6, 18),
    )
    _add_expense(
        db,
        store=store,
        user=user,
        category="OTHER",
        amount=dec(650),
        note="Cleaning supplies",
        created_at=_dt(0, 8, 30),
    )

    # Sales mix for reports, low-stock, fast movers, and credit aging.
    _add_sale(
        db,
        store=store,
        user=user,
        products=products,
        customer=None,
        created_at=_dt(0, 9, 15),
        items=[("noodles", dec(12)), ("biscuits", dec(6))],
        sale_type="CASH",
        note_key="today_cash_1",
    )
    _add_sale(
        db,
        store=store,
        user=user,
        products=products,
        customer=customers["sita"],
        created_at=_dt(1, 19, 20),
        items=[("oil_1l", dec(2)), ("rice_1kg", dec(5))],
        sale_type="CREDIT",
        note_key="sita_credit_recent",
    )
    _add_sale(
        db,
        store=store,
        user=user,
        products=products,
        customer=customers["ram"],
        created_at=_dt(18, 17, 30),
        items=[("rice_1kg", dec(4)), ("sugar_1kg", dec(4))],
        sale_type="CREDIT",
        note_key="ram_credit_overdue",
    )
    _add_sale(
        db,
        store=store,
        user=user,
        products=products,
        customer=customers["rohan"],
        created_at=_dt(45, 16, 10),
        items=[("rice_1kg", dec(2)), ("oil_1l", dec(1))],
        sale_type="CREDIT",
        note_key="rohan_credit_old",
    )
    _add_sale(
        db,
        store=store,
        user=user,
        products=products,
        customer=customers["gopal"],
        created_at=_dt(3, 14, 0),
        items=[("milk_1l", dec(4)), ("tea_250g", dec(2))],
        sale_type="CASH",
        split_methods=[("CASH", dec(500)), ("QR", dec(220))],
        note_key="gopal_split_cash_qr",
    )
    # Sell all sugar so it becomes out-of-stock and below threshold.
    _add_sale(
        db,
        store=store,
        user=user,
        products=products,
        customer=None,
        created_at=_dt(0, 11, 45),
        items=[("sugar_1kg", dec(6))],
        sale_type="CASH",
        note_key="sugar_sellout_1",
    )
    _add_sale(
        db,
        store=store,
        user=user,
        products=products,
        customer=None,
        created_at=_dt(0, 17, 5),
        items=[("sugar_1kg", dec(4))],
        sale_type="CASH",
        note_key="sugar_sellout_2",
    )
    # Fast movers in last 7d.
    for i, qty in enumerate((10, 8, 12, 9, 11), start=1):
        _add_sale(
            db,
            store=store,
            user=user,
            products=products,
            customer=None,
            created_at=_dt(i, 10 + (i % 4), 5 * i),
            items=[("noodles", dec(qty))],
            sale_type="CASH",
            note_key=f"noodles_fast_{i}",
        )

    # Credit repayments (partial/full) to create aging buckets and payer behavior.
    _add_customer_payment(
        db,
        store=store,
        user=user,
        customer=customers["sita"],
        amount=dec(400),
        created_at=_dt(0, 18, 30),
        note="Sita partial payment",
    )
    _add_customer_payment(
        db,
        store=store,
        user=user,
        customer=customers["ram"],
        amount=dec(150),
        created_at=_dt(7, 12, 0),
        note="Ram small payment",
    )

    # Emit final product/customer snapshots after stock/balance changes.
    db.flush()
    for p in products.values():
        SyncEventService.emit(
            db,
            store_id=store.id,
            entity="product",
            operation="UPSERT",
            payload=SyncEventService.product_payload(p),
        )
    for c in customers.values():
        SyncEventService.emit(
            db,
            store_id=store.id,
            entity="customer",
            operation="UPSERT",
            payload=SyncEventService.customer_payload(c),
        )

    # Compute/cache customer metrics + alerts so APIs/screens show immediate data.
    IntelligenceService.compute_customer_metrics(db, store.id)
    IntelligenceService.compute_and_cache_open_alerts(db, store.id)
    db.flush()

    return {
        "products": len(products),
        "customers": len(customers),
        "sales": db.query(Sale).filter(Sale.store_id == store.id).count(),
        "expenses": db.query(Expense).filter(Expense.store_id == store.id).count(),
        "customer_payments": db.query(CustomerPayment)
        .filter(CustomerPayment.store_id == store.id)
        .count(),
        "sync_events": db.query(SyncEvent).filter(SyncEvent.store_id == store.id).count(),
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Reset and seed a single deterministic demo account/store.",
    )
    parser.add_argument("--phone", default=DEMO_PHONE)
    parser.add_argument("--password", default=DEMO_PASSWORD)
    parser.add_argument("--reset-only", action="store_true")
    parser.add_argument("--seed-only", action="store_true")
    parser.add_argument("--full-reset-seed", action="store_true")
    args = parser.parse_args()

    if args.reset_only and args.seed_only:
        parser.error("Use only one of --reset-only or --seed-only")

    do_reset = args.reset_only or args.full_reset_seed or not args.seed_only
    do_seed = args.seed_only or args.full_reset_seed or not args.reset_only

    run_sqlite_compat_migrations()
    Base.metadata.create_all(bind=engine)

    with SessionLocal() as db:
        try:
            reset_stats: dict[str, int] = {}
            if do_reset:
                reset_stats = reset_demo_account(db, phone=args.phone)

            user = db.scalar(select(User).where(User.phone == args.phone))
            store = None
            if user is not None:
                store = db.scalar(select(Store).where(Store.owner_user_id == user.id))

            if do_seed:
                if user is None or store is None:
                    user, store = ensure_demo_user_store(
                        db,
                        phone=args.phone,
                        password=args.password,
                    )
                seed_stats = seed_demo_data(db, user=user, store=store)
            else:
                seed_stats = {}

            db.commit()
        except Exception:
            db.rollback()
            raise

    print("Demo account reset/seed complete")
    print(f"  phone: {args.phone}")
    print(f"  reset: {do_reset}")
    print(f"  seed: {do_seed}")
    if do_reset:
        print(f"  reset_stats: {reset_stats}")
    if do_seed:
        print(f"  seed_stats: {seed_stats}")


if __name__ == "__main__":
    main()
