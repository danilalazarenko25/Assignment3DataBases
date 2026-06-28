create table customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

create table products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

create table order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

create table order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);

-- task 1
create or replace function calculate_order_total(id_of_order int)
returns numeric(10,2) as $$
declare
    calculated_sum numeric(10,2);
begin
    select coalesce(sum(quantity * price), 0.00)
    into calculated_sum
    from order_items
    where order_id = id_of_order;

    return calculated_sum;
end;
$$ language plpgsql;

-- task 2
create or replace procedure create_order(id_of_customer int)
language plpgsql
as $$
begin
    insert into orders (customer_id, order_date, total_amount)
    values (id_of_customer, current_timestamp, 0.00);
end;
$$;

-- task 3
create or replace procedure add_product_to_order(
    target_order_id int,
    target_product_id int,
    item_quantity int
)
language plpgsql
as $$
declare
    current_price numeric(10,2);
begin
    select price into current_price
    from products
    where product_id = target_product_id;

    insert into order_items (order_id, product_id, quantity, price)
    values (target_order_id, target_product_id, item_quantity, current_price);

    update products
    set stock_quantity = stock_quantity - item_quantity
    where product_id = target_product_id;
end;
$$;

-- task 4
create or replace function fn_sync_order_total()
returns trigger as $$
declare
    chosen_order_id int;
begin
    if lower(tg_op) = 'delete' then
        chosen_order_id := old.order_id;
    else
        chosen_order_id := new.order_id;
    end if;

    update orders
    set total_amount = calculate_order_total(chosen_order_id)
    where order_id = chosen_order_id;

    return null;
end;
$$ language plpgsql;

create trigger trg_sync_order_total
after insert or update or delete on order_items
for each row
execute function fn_sync_order_total();

-- task 5
create or replace function fn_log_created_orders()
returns trigger as $$
begin
    insert into order_log (order_id, customer_id, action, log_date)
    values (new.order_id, new.customer_id, 'order created', current_timestamp);
    return null;
end;
$$ language plpgsql;

create trigger trg_log_created_orders
after insert on orders
for each row
execute function fn_log_created_orders();







select * from orders;

select * from order_log;

select * from products;
