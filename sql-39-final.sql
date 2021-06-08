set search_path to bookings;

-- 1	� ����� ������� ������ ������ ���������?	
select city "�����"
from airports a
group by city 
having count(airport_code) > 1;


-- 2	� ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?	- ���������
explain analyse 
select distinct 
	a.airport_name "��������"
from airports a  
join flights f on a.airport_code = f.departure_airport 
where f.aircraft_code = (
	select a.aircraft_code 
	from aircrafts a 
	order by a."range" desc limit 1
);


-- 3	������� 10 ������ � ������������ �������� �������� ������	- �������� LIMIT
select 
	f.flight_id,
	ad.airport_name "Departure Airport",
	aa.airport_name "Arrival Airport",
	f.scheduled_departure,
	f.actual_departure,
	f.actual_departure - f.scheduled_departure "��������"
from flights f
join airports ad on ad.airport_code = f.departure_airport 
join airports aa on aa.airport_code = f.arrival_airport 
where f.actual_departure is not null
order by "��������" desc
limit 10;


-- 4	���� �� �����, �� ������� �� ���� �������� ���������� ������?	- ������ ��� JOIN
select 
	case when count(b.book_ref) > 0 then '��'
	else '���'
	end "������� ������ ��� ��",
	count(b.book_ref) "�� ����������" 
from bookings b 
join tickets t on t.book_ref = b.book_ref 
left join boarding_passes bp on bp.ticket_no = t.ticket_no 
where bp.boarding_no is null;


-- 5	������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
-- �������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� 
-- �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.	
-- - ������� �������
-- - ���������� ��� cte
with boarded as (
	select 
		f.flight_id,
		f.flight_no,
		f.aircraft_code,
		f.departure_airport,
		f.scheduled_departure,
		f.actual_departure,
		count(bp.boarding_no) boarded_count
	from flights f 
	join boarding_passes bp on bp.flight_id = f.flight_id 
	where f.actual_departure is not null
	group by f.flight_id 
),
max_seats_by_aircraft as(
	select 
		s.aircraft_code,
		count(s.seat_no) max_seats
	from seats s 
	group by s.aircraft_code 
)
select 
	b.flight_no,
	b.departure_airport,
	b.scheduled_departure,
	b.actual_departure,
	b.boarded_count,
	m.max_seats - b.boarded_count free_seats, 
	round((m.max_seats - b.boarded_count) / m.max_seats :: dec, 2) * 100 free_seats_percent,
	sum(b.boarded_count) over (partition by (b.departure_airport, b.actual_departure::date) order by b.actual_departure) "������������ ����������"
from boarded b 
join max_seats_by_aircraft m on m.aircraft_code = b.aircraft_code;

-- 6	������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.	- ���������
-- - �������� ROUND
select 
	a.model "������ ��������",
	count(f.flight_id) "���������� ������",
	round(count(f.flight_id) / 
		(select 
			count(f.flight_id)
		from flights f 
		where f.actual_departure is not null
		)::dec, 2) * 100 "� ��������� �� ������ �����"
from aircrafts a 
join flights f on f.aircraft_code = a.aircraft_code 
where f.actual_departure is not null
group by a.aircraft_code;

-- 7	���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?	- CTE
with prices_by_flight as (
	select  distinct 
		f.flight_id,
		a.city dep_city,
		a2.city arr_city,
		case when tf.fare_conditions = 'Economy' 
			then tf.amount 
			else -tf.amount
		end amount
	from ticket_flights tf 
	join flights f on tf.flight_id = f.flight_id 
	join airports a on f.departure_airport = a.airport_code
	join airports a2 on f.arrival_airport = a2.airport_code
)
select 
	pbf.flight_id,
	pbf.dep_city,
	pbf.arr_city,
	sum(pbf.amount)
from prices_by_flight pbf
group by pbf.flight_id, pbf.dep_city, pbf.arr_city
having 	sum(pbf.amount) > 0


-- 8	����� ������ �������� ��� ������ ������?	- ��������� ������������ � ����������� FROM
-- - �������������� ��������� �������������
-- - �������� EXCEPT


-- 9	��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� ����� *	- �������� RADIANS ��� ������������� sind/cosd
-- - CASE 

