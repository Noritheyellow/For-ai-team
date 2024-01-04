/* Demographic materialized view (David, 2023.07.19.)
 * 
 * subject_id, gender, age, admittime, dischtime, weight_kg, height_inches, height_cm, bmi를 갖고 있는 Materialized view table 이다.
 * 
 * view_weight와 view_height를 [subject_id, gender, age, admittime, dischtime]에 대하여 inner join 하였다.
 *
 * Excluded:
 *      - 키와 체중을 둘 다 가지고 있는 환자들을 대상으로 한다.(교집합)
 *      - 이상치를 제거한다 in python, z-score를 이용한 통계적 이상치 제거를 시도해보자.
*/

DROP MATERIALIZED VIEW IF EXISTS view_raw_demographic;
CREATE MATERIALIZED VIEW view_raw_demographic AS (
SELECT vw.*, vh.height_inches, vh.height_cm
		, round(weight_kg/power(vh.height_cm/100, 2),1) AS bmi
  FROM view_weight vw 
 INNER JOIN view_height vh 
    ON vw.subject_id = vh.subject_id 
   AND vw.gender = vh.gender 
   AND vw.age = vh.age 
   AND vw.admittime = vh.admittime 
   AND vw.dischtime = vh.dischtime 
)
;

CREATE INDEX ix_view_raw_demographic_sbj_admit ON view_raw_demographic(subject_id, admittime);

SELECT *
  FROM view_raw_demographic vrd
;
-- count: 11,871
-- distinct subject id: 10,769
-- distinct admittime: 11,812

