/*
 * Original Dataset
*/  
SELECT count(*)
  FROM patients p 
  LEFT JOIN admissions a 
    ON p.subject_id = a.subject_id 
;
-- count: 58,976
-- distinct subject id: 46,520


/* Demographic view (David, 2023.07.19.)
 * 
 * 환자의 ID, 성별, 생일, 입원일자, 퇴원일자, 나이를 담고 있는 View table 이다.
 * 나이는 환자의 입원날짜를 생일과 빼서 계산한다. 
 * age > 89 인 환자는 300 이상의 숫자로 표시되기 때문에 210을 추가로 빼준 age_adjusted 컬럼을 만들어준다.
 * age = 0 인 환자들은 테이블에서 배제한다.
 * 입/퇴원일자를 담은 이유는 WFDB에서 동잃 환자더라도 신호가 기록된 날짜에 따라 다른 환자정보가 적용되게 해야 하기 때문이다.
 *
 * Excluded:
 *		- age = 0인 환자들 (count: 8,110 / distinct subject id: 7,874)
*/
DROP VIEW IF EXISTS view_personBasic;
CREATE VIEW view_personBasic AS (
WITH step0 AS (
	SELECT p.subject_id, p.gender, p.dob, a.admittime, a.dischtime 
	  FROM patients p 
	  LEFT JOIN admissions a 
	    ON p.subject_id = a.subject_id 
)
, step1 AS (
	SELECT subject_id, gender, dob, admittime, dischtime
			, round(((admittime::DATE)-(dob::DATE))/365.242, 0) AS age
			, ROUND((CAST(EXTRACT(epoch FROM admittime - dob)/(60*60*24*365.242) AS numeric)), 4) AS age2
			, round(((admittime::DATE)-(dob::DATE))/365.242, 0) - 210 AS age_adjusted
	  FROM step0
)
, step2 AS (
	SELECT subject_id, gender, dob, admittime, dischtime
			, CASE WHEN age >= 300 THEN age_adjusted
					ELSE age
			END age
	  FROM step1
	 WHERE age != 0
)
SELECT *
  FROM step2
 ORDER BY subject_id asc
);

SELECT * FROM view_personBasic d; 
-- count: 50,866
-- distinct subject id: 38,646
-- 중복이 존재함.