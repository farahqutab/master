CREATE TABLE `inventory_movements_data` (
  `movement_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `movement_type` text,
  `quantity_moved` int DEFAULT NULL,
  `movement_date` text
) ;
