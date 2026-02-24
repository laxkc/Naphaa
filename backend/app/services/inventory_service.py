from decimal import Decimal

from fastapi import status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.errors import raise_api_error
from app.models.product import Product


class InventoryService:
    @staticmethod
    def get_product_for_store(db: Session, store_id: str, product_id: str) -> Product:
        product = db.scalar(
            select(Product).where(
                Product.id == product_id,
                Product.store_id == store_id,
                Product.is_deleted.is_(False),
            )
        )
        if product is None:
            raise_api_error(status.HTTP_404_NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found")
        return product

    @staticmethod
    def deduct_stock(db: Session, product: Product, qty: Decimal) -> None:
        qty_decimal = Decimal(qty)
        if qty_decimal <= 0:
            raise_api_error(
                status.HTTP_400_BAD_REQUEST,
                "INVALID_STOCK_QTY",
                "qty must be greater than zero",
            )
        result = db.execute(
            update(Product)
            .where(
                Product.id == product.id,
                Product.store_id == product.store_id,
                Product.is_deleted.is_(False),
                Product.stock_qty >= qty_decimal,
            )
            .values(stock_qty=Product.stock_qty - qty_decimal)
        )
        if (result.rowcount or 0) == 0:
            raise_api_error(
                status.HTTP_400_BAD_REQUEST,
                "INSUFFICIENT_STOCK",
                f"Insufficient stock for product {product.name}",
            )
        db.refresh(product)

    @staticmethod
    def adjust_stock(db: Session, product: Product, delta_qty: Decimal) -> Decimal:
        delta = Decimal(delta_qty)
        result = db.execute(
            update(Product)
            .where(
                Product.id == product.id,
                Product.store_id == product.store_id,
                Product.is_deleted.is_(False),
                Product.stock_qty + delta >= 0,
            )
            .values(stock_qty=Product.stock_qty + delta)
        )
        if (result.rowcount or 0) == 0:
            raise_api_error(
                status.HTTP_400_BAD_REQUEST,
                "INSUFFICIENT_STOCK",
                "Stock cannot go below zero",
            )
        db.refresh(product)
        return Decimal(product.stock_qty)
