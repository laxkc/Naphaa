from decimal import Decimal

import pytest
from fastapi import HTTPException

from app.models.customer import Customer
from app.models.product import Product
from app.models.sale import Sale
from app.schemas.sale import SaleCreate, SaleItemCreate, SaleType
from app.services.sale_service import SaleService


def test_create_cash_sale_deducts_stock_and_sets_total(db_session):
    product = Product(
        store_id="store-1",
        name="Sugar",
        sell_price=Decimal("50"),
        stock_qty=Decimal("20"),
    )
    db_session.add(product)
    db_session.commit()

    payload = SaleCreate(
        sale_type=SaleType.CASH,
        items=[SaleItemCreate(product_id=product.id, qty=Decimal("2"), unit_price=Decimal("55"))],
    )

    sale = SaleService.create_sale(db_session, "store-1", payload, actor_user_id="user-1")

    assert Decimal(sale.total_amount) == Decimal("110")
    assert Decimal(product.stock_qty) == Decimal("18")


def test_create_credit_sale_updates_customer_balance(db_session):
    product = Product(
        store_id="store-1",
        name="Milk",
        sell_price=Decimal("80"),
        stock_qty=Decimal("10"),
    )
    customer = Customer(store_id="store-1", name="Ram", balance=Decimal("0"))
    db_session.add_all([product, customer])
    db_session.commit()

    payload = SaleCreate(
        sale_type=SaleType.CREDIT,
        customer_id=customer.id,
        items=[SaleItemCreate(product_id=product.id, qty=Decimal("1"), unit_price=Decimal("80"))],
    )

    SaleService.create_sale(db_session, "store-1", payload, actor_user_id="user-1")
    db_session.refresh(customer)
    assert Decimal(customer.balance) == Decimal("80")


def test_create_credit_sale_invalid_customer(db_session):
    product = Product(
        store_id="store-1",
        name="Tea",
        sell_price=Decimal("25"),
        stock_qty=Decimal("10"),
    )
    db_session.add(product)
    db_session.commit()

    payload = SaleCreate(
        sale_type=SaleType.CREDIT,
        customer_id="missing-customer",
        items=[SaleItemCreate(product_id=product.id, qty=Decimal("1"), unit_price=Decimal("25"))],
    )

    with pytest.raises(HTTPException) as exc:
        SaleService.create_sale(db_session, "store-1", payload, actor_user_id="user-1")

    assert exc.value.status_code == 404


def test_create_sale_with_large_transaction_values(db_session):
    product = Product(
        store_id="store-1",
        name="Bulk Rice",
        sell_price=Decimal("9999999.99"),
        stock_qty=Decimal("1000000"),
    )
    db_session.add(product)
    db_session.commit()

    payload = SaleCreate(
        sale_type=SaleType.CASH,
        items=[
            SaleItemCreate(
                product_id=product.id,
                qty=Decimal("100"),
                unit_price=Decimal("9999999.99"),
            )
        ],
    )

    SaleService.create_sale(db_session, "store-1", payload, actor_user_id="user-1")
    sale = db_session.query(Sale).first()
    assert sale is not None
    assert Decimal(sale.total_amount) == Decimal("999999999.00")
