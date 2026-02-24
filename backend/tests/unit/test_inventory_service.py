from decimal import Decimal

import pytest
from fastapi import HTTPException

from app.models.product import Product
from app.services.inventory_service import InventoryService


def test_deduct_stock_success(db_session):
    product = Product(
        store_id="store-1",
        name="Rice",
        sell_price=Decimal("100"),
        stock_qty=Decimal("10"),
    )
    db_session.add(product)
    db_session.commit()

    InventoryService.deduct_stock(db_session, product, Decimal("3"))
    db_session.commit()

    assert Decimal(product.stock_qty) == Decimal("7")


def test_deduct_stock_never_negative(db_session):
    product = Product(
        store_id="store-1",
        name="Oil",
        sell_price=Decimal("200"),
        stock_qty=Decimal("1"),
    )
    db_session.add(product)
    db_session.commit()

    with pytest.raises(HTTPException) as exc:
        InventoryService.deduct_stock(db_session, product, Decimal("2"))

    assert exc.value.status_code == 400
