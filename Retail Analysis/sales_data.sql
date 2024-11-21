CREATE TABLE `sales_data` (
  `sale_id` int DEFAULT NULL,
  `customer_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `quantity_sold` int DEFAULT NULL,
  `sale_date` text,
  `discount_applied` int DEFAULT NULL,
  `total_amount` double DEFAULT NULL
);
