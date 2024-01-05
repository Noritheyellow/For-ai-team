-- https://opendata.stackexchange.com/questions/6397/is-the-patients-height-available 참고

/*
 * Original Weight Dataset
 * count: 81,215 / distinct subject id: 21,062
*/  
SELECT c.subject_id, td.gender, td.age, c.itemid, td.admittime, c.charttime, td.dischtime, c.value, c.valuenum, c.valueuom
  FROM view_personBasic td 
  LEFT JOIN chartevents c 
    ON (td.subject_id = c.subject_id
        AND (c.charttime >= td.admittime AND c.charttime < td.dischtime)
    )
 WHERE 1=1
   AND itemid in (762, 763, 3723, 3580)  -- weight Kg
;


/* Weight view (David, 2023.07.19.)
 * 
 * subject_id, gender, age, itemid, admittime, charttime, dischtime, weight_kg을 갖고 있는 View table 이다.
 * 
 * 1) 체중의 단위에 대하여
 *      본 데이터베이스에는 Kg, lb, oz의 세 단위가 존재한다. (count: 81,215)
 *      이 중에서 가장 지배적인 단위는 Kg이며, 심지어 lb, oz는 본 추출한 데이터 상에는 존재하지도 않는다. (count: 81,215)
 *      
 * 2) 체중 관련 item id
 *      [762, 763, 3723, 3580]
 *
 * 3) 모든 체중은 소수점 1자리까지 반올림 되었다.
 *
 * Excluded:
 *      - `value` 혹은 `valuenum`이 모두 Null인 record (count: 8,225 / distinct subject id: 6,664)
 *      - 계산된 `weight_kg` = 0 인 record(count: 67)
*/
DROP VIEW IF EXISTS view_weight_raw;
CREATE VIEW view_weight_raw AS (
	WITH step0 AS (
		SELECT c.subject_id, td.gender, td.age, c.itemid, td.admittime, c.charttime, td.dischtime, c.value, c.valuenum, c.valueuom
		  FROM view_personBasic td 
		  LEFT JOIN chartevents c 
		    ON (td.subject_id = c.subject_id
		    	AND (c.charttime >= td.admittime AND c.charttime < td.dischtime)
		    )
		 WHERE 1=1
		   AND itemid in (762, 763, 3723, 3580  -- weight Kg
		-- 				, 3581					-- weight lb
		-- 				, 3582					-- weight oz
		 				)
	)
	, step1 AS (
		SELECT subject_id, gender, age, itemid, admittime, charttime, dischtime, value, valuenum, valueuom
		  FROM step0
		 WHERE (value IS NOT NULL) OR (valuenum IS NOT NULL)
	)
	, step2 AS (
		SELECT subject_id, gender, age, itemid, admittime, charttime, dischtime
				, CASE 
					WHEN round(value::NUMERIC, 1)::NUMERIC IS NULL THEN round(valuenum::NUMERIC, 1)
					WHEN round(valuenum::NUMERIC, 1) IS NULL THEN round(value::NUMERIC, 1)
					ELSE round(value::NUMERIC, 1) 
				END weight_kg
		  FROM step1
	)
	SELECT *
	  FROM step2
     WHERE weight_kg != 0
)
;

SELECT * FROM view_weight_raw vwr;
-- count: 72,923
-- distinct subject id: 19,137 <-- 이 값은 subject id에 중복이 발생하여 원본 수에서 그대로 빼면 안 맞을 수가 있다. 그러므로 여기서는 count를 참고하자.


-- 각 환자별로 해당 admittime에는 하나의 weight만 있게 하자.
DROP VIEW IF EXISTS view_weight;
CREATE VIEW view_weight AS (
	SELECT subject_id, gender, age, admittime, dischtime, round(AVG(weight_kg),1) AS weight_kg 
	  FROM view_weight_raw vwr 
	 GROUP BY subject_id, gender, age, admittime, dischtime
)
;
-- count: 22,775 (하나의 ID에도 여러 개의 admittime이 존재하기 때문)
-- distinct subject id: 19,137
-- distinct admittime: 22,689


------------------------------------------------------------------------------------------------------------------------------------
/*
 * Original Height Dataset
 * count: 35,975 / distinct subject id: 20,137
*/  
SELECT c.subject_id, td.gender, td.age, c.itemid, td.admittime, c.charttime, td.dischtime, c.value, c.valuenum, c.valueuom
  FROM view_personBasic td 
  LEFT JOIN chartevents c 
    ON (td.subject_id = c.subject_id
    	AND (c.charttime >= td.admittime AND c.charttime < td.dischtime)
    )
 WHERE 1=1
   AND itemid in (920, 1394, 4187, 3486)	-- height inches
;


/* Height view (David, 2023.07.19.)
 * 
 * subject_id, gender, age, itemid, admittime, charttime, dischtime, height_cm를 갖고 있는 View table 이다.
 * 
 * 1) 신장의 단위에 대하여
 *      본 데이터베이스에는 inches, cm의 두 단위가 존재한다. (count: 35,975)
 *      이 중에서 가장 지배적인 단위는 inches이며, cm는 존재하지 않는다. (count: 35,975)
 *
 * 2) 신장 관련 item id
 *      [920, 1394, 4187, 3486]
 *      
 * 3) 모든 inches는 cm 단위로 계산되었다. 
 *      1 inches = 2.54 cm
 *
 * Excluded:
 *      - `value` 혹은 `valuenum`이 모두 Null인 record (count: 18,366 / distinct subject id: 11,927)
 *      - 계산된 `weight_kg` = 0 인 record(count: 18)
*/
DROP VIEW IF EXISTS view_height_raw;
CREATE VIEW view_height_raw AS (
	WITH step0 AS (
		SELECT c.subject_id, td.gender, td.age, c.itemid, td.admittime, c.charttime, td.dischtime, c.value, c.valuenum, c.valueuom
		  FROM view_personBasic td 
		  LEFT JOIN chartevents c 
		    ON (td.subject_id = c.subject_id
		    	AND (c.charttime >= td.admittime AND c.charttime < td.dischtime)
		    )
		 WHERE 1=1
		   AND itemid in (920, 1394, 4187, 3486)	-- height inches
	)
	, step1 AS (
		SELECT subject_id, gender, age, itemid, admittime, charttime, dischtime, value, valuenum, valueuom
		  FROM step0
		 WHERE (value IS NOT NULL) OR (valuenum IS NOT NULL)
	)
	, step2 AS (
		SELECT subject_id, gender, age, itemid, admittime, charttime, dischtime
				, CASE 
					WHEN value::NUMERIC IS NULL THEN valuenum
					WHEN valuenum IS NULL THEN value::NUMERIC 
					ELSE value::NUMERIC 
				END height_inches
		  FROM step1
	)
	, step3 AS (
		SELECT *
		  FROM step2
		 WHERE height_inches != 0
	)
	SELECT *, (height_inches * 2.54) AS height_cm
	  FROM step3	
)
;

SELECT * FROM view_height_raw vhr;
-- count: 17,591
-- distinct subject id: 10,785


-- 각 환자별로 해당 (admittime, dischtime)에는 하나의 height만 있게 하자.
DROP VIEW IF EXISTS view_height;
CREATE VIEW view_height AS (
	SELECT subject_id, gender, age, admittime, dischtime
			, round(AVG(height_inches::NUMERIC),1) AS height_inches
			, round(AVG(height_cm::NUMERIC),1) AS height_cm
	  FROM view_height_raw vhr
	 GROUP BY subject_id, gender, age, admittime, dischtime
)
;
-- count: 11,888
-- distinct subject id: 10,785
-- distinct admittime: 11,829


