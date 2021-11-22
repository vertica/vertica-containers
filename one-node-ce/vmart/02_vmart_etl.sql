-- (c) Copyright [2021] Micro Focus or one of its affiliates.
-- Licensed under the Apache License, Version 2.0 (the "License");
-- You may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Add timestamp columns into facts tables
-- Most of use cases can utilize timestamp columns and corresponding SQL functions instead of joining date_dimension table.
-- Joining date_dimension table has significant negative impact on performance
-- Utilize flatten tables everywhere it works

alter table online_sales.online_sales_fact add column online_sales_saledate DATE DEFAULT (SELECT date FROM public.date_dimension WHERE online_sales.online_sales_fact.sale_date_key = public.date_dimension.date_key);
alter table online_sales.online_sales_fact add column online_sales_shipdate DATE DEFAULT (SELECT date FROM public.date_dimension WHERE online_sales.online_sales_fact.ship_date_key = public.date_dimension.date_key);
alter table public.inventory_fact add column inventory_date DATE DEFAULT (SELECT date FROM public.date_dimension WHERE public.inventory_fact.date_key = public.date_dimension.date_key);
alter table store.store_sales_fact add column store_sales_date DATE DEFAULT (SELECT date FROM public.date_dimension WHERE store.store_sales_fact.date_key = public.date_dimension.date_key);

alter table store.store_sales_fact add column store_sales_datetime TIMESTAMP;
update store.store_sales_fact set store_sales_datetime = to_date(to_char(store_sales_date, 'yyyy-mm-dd')||' '||to_char(transaction_time, 'hh24:mi:ss'), 'yyyy-mm-dd hh24:mi:ss');
commit;
