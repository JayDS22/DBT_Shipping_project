SELECT 
    OrderItemID,
    OrderID,
    ProductID,
    Quantity,
    UnitPrice,
    Quantity * UnitPrice AS TotalPrice,
    updated_at
FROM 
    L1_LANDING.ORDERITEMS
    