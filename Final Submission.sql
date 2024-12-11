use ipl;

show tables;

/*
ipl_bidder_details
ipl_bidder_points
ipl_bidding_details
ipl_match
ipl_match_schedule
ipl_player
ipl_stadium
ipl_team
ipl_team_players
ipl_team_standings
ipl_tournament
ipl_user
*/

-- 1.	Show the percentage of wins of each bidder in the order of highest to lowest percentage.

select * from ipl_bidding_details;
select * from ipl_bidder_details;
select * from ipl_bidder_points;

with bid_wins as (
			select bidding_d.bidder_id,count(bidding_d.bid_status) wins
			from ipl_bidding_details bidding_d
			where bidding_d.bid_status = 'Won'
			group by bidding_d.bidder_id)
            
select bidder_d.*,(bid_wins.wins/bidder_p.no_of_bids)*100 percentage from bid_wins
join ipl_bidder_points bidder_p on bid_wins.bidder_id = bidder_p.bidder_id
join ipl_bidder_details bidder_d on bidder_p.bidder_id = bidder_d.bidder_id
order by percentage desc;


-- 2.	Display the number of matches conducted at each stadium with the stadium name and city.

select * from ipl_match_schedule;
select * from ipl_stadium;

SELECT 
    ms.STADIUM_ID,
    s.STADIUM_NAME,
    s.CITY,
    COUNT(ms.MATCH_ID) total_matches_played
FROM
    ipl_match_schedule ms
JOIN
    ipl_stadium s ON ms.STADIUM_ID = s.STADIUM_ID
GROUP BY ms.STADIUM_ID , s.STADIUM_NAME , s.CITY;


-- 3.	In a given stadium, what is the percentage of wins by a team that has won the toss?


select * from ipl_match;
select * from ipl_stadium;
select * from ipl_match_schedule;
SELECT 
    s.STADIUM_NAME,
    (SUM(CASE
        WHEN m.TOSS_WINNER = m.MATCH_WINNER THEN 1
        ELSE 0
    END) / COUNT(*)) * 100 percentage_of_wins
FROM
    ipl_match m
JOIN
    ipl_match_schedule ms ON m.MATCH_ID = ms.MATCH_ID
JOIN
    ipl_stadium s ON ms.STADIUM_ID = s.STADIUM_ID
GROUP BY s.STADIUM_NAME
ORDER BY 1;


-- 4.	Show the total bids along with the bid team and team name.

		select * from ipl_team;
		select * from ipl_bidder_points;
		select * from ipl_bidding_details;
        
SELECT 
    bd.BID_TEAM, t.TEAM_NAME, SUM(bp.no_of_bids)
FROM
    ipl_bidder_points bp
JOIN
    ipl_bidding_details bd ON bp.bidder_id = bd.bidder_id
JOIN
    ipl_team t ON bd.BID_TEAM = t.TEAM_ID
GROUP BY bd.BID_TEAM , t.TEAM_NAME;


-- 5.	Show the team ID who won the match as per the win details.

SELECT
			m.MATCH_ID,
			m.TEAM_ID1,
			t1.TEAM_NAME AS TEAM1_NAME,
			m.TEAM_ID2,
			t2.TEAM_NAME AS TEAM2_NAME,
			m.MATCH_WINNER AS WINNER_TEAM_IDS
FROM
			ipl_match m
LEFT JOIN
			ipl_team t1 ON m.TEAM_ID1 = t1.TEAM_ID
LEFT JOIN
			ipl_team t2 ON m.TEAM_ID2 = t2.TEAM_ID;
            
       
-- 6.	Display the total matches played, total matches won and total matches lost by the team along with its team name.

SELECT 
    t.team_id,
    SUM(ts.MATCHES_PLAYED),
    SUM(ts.matches_won),
    SUM(ts.matches_lost),
    t.TEAM_NAME
FROM
    ipl_team t
        INNER JOIN
    ipl_team_standings ts ON t.team_id = ts.team_id
GROUP BY 1;

select* from ipl_team_standings;
select* from ipl_team;


-- 7.	Display the bowlers for the Mumbai Indians team.

select * from ipl_team_players;
select* from ipl_team;

SELECT 
    t.team_id, t.TEAM_NAME, tp.PLAYER_ROLE, p.player_name
FROM
    ipl_team t
        INNER JOIN
    ipl_team_players tp ON t.team_id = tp.team_id
        INNER JOIN
    ipl_player p ON tp.player_id = p.player_id
WHERE
    t.team_id = (SELECT 
            team_id
        FROM
            ipl_team
        WHERE
            TEAM_NAME = 'Mumbai Indians')
        AND tp.PLAYER_ROLE = 'bowler';
        

-- 8.	How many all-rounders are there in each team, Display the teams with more than 4 
-- all-rounders in descending order.

SELECT 
    t.team_name, COUNT(*) AS No_of_allrounders
FROM
    ipl_team t
        INNER JOIN
    ipl_team_players tp ON t.team_id = tp.team_id
WHERE
    tp.player_role = 'All-Rounder'
GROUP BY 1
HAVING COUNT(*) > 4
ORDER BY No_of_allrounders DESC;


-- 9.Write a query to get the total bidders' points for each bidding status of those bidders who bid on
--   CSK when they won the match in M. Chinnaswamy Stadium bidding year-wise.
--   Note the total bidders’ points in descending order and the year is the bidding year.
--   Display columns: bidding status, bid date as year, total bidder’s points

select * from ipl_match;

SELECT 
    bd.bid_status,
    YEAR(bd.bid_date) AS Year1,
    SUM(bp.total_points) AS Total_points
FROM
    ipl_bidder_points bp
        INNER JOIN
    ipl_bidding_details bd ON bp.bidder_id = bd.bidder_id
        JOIN
    ipl_bidder_details bd2 ON bd2.bidder_id = bd.bidder_id
        JOIN
    ipl_match_schedule ms ON ms.schedule_id = bd.schedule_id
        JOIN
    ipl_match m ON m.match_id = ms.match_id
        JOIN
    ipl_stadium s ON s.stadium_id = ms.stadium_id
WHERE
    s.STADIUM_NAME = 'M. Chinnaswamy Stadium'
        AND m.win_details LIKE '%CSK%'
GROUP BY 1 , 2
ORDER BY Total_points DESC;

select * from ipl_stadium;
select* from ipl_match;


-- 10.	Extract the Bowlers and All-Rounders that are in the 5 highest number of wickets.
-- Note 
-- 1. Use the performance_dtls column from ipl_player to get the total number of wickets
--  2. Do not use the limit method because it might not give appropriate results when players have the same number of wickets
-- 3.	Do not use joins in any cases.
-- 4.	Display the following columns teamn_name, player_name, and player_role.

with temp as (
        SELECT 
			T.TEAM_NAME,
			P.PLAYER_NAME,
			TP.PLAYER_ROLE,
			substr(P.PERFORMANCE_DTLS,instr(P.PERFORMANCE_DTLS,'Wkt-')+4,2) AS WICKETS,
			DENSE_RANK() OVER (ORDER BY substr(P.PERFORMANCE_DTLS,instr(P.PERFORMANCE_DTLS,'Wkt-')+4,2) DESC) AS max_RANK
		FROM 
			IPL_TEAM T,
			IPL_TEAM_PLAYERS TP,
			IPL_PLAYER P
		WHERE 
			T.TEAM_ID = TP.TEAM_ID
			AND TP.PLAYER_ID = P.PLAYER_ID
			AND (TP.PLAYER_ROLE = 'Bowler' OR TP.PLAYER_ROLE = 'All-Rounder')
		)
        select TEAM_NAME,
			PLAYER_NAME,
			PLAYER_ROLE,WICKETS,max_RANK from temp where max_RANK <= 5;
            

-- 11.	show the percentage of toss wins of each bidder and display the results in descending order based on the percentage

SELECT  *
FROM
    ipl_bidding_details;
SELECT  *
FROM ipl_match;
SELECT *
FROM
    ipl_match_schedule;
	
		with temp as (
		select bd.bidder_ID,count(m.TOSS_WINNER) toss_won_count_of_each_bidder
		from ipl_bidding_details bd join ipl_match_schedule ms 
		on bd.Schedule_ID = ms.Schedule_ID
		join ipl_match m on ms.MATCH_ID = m.MATCH_ID
		group by bd.bidder_ID
		)
		select bidder_ID,sum(toss_won_count_of_each_bidder) as total_toss_won_count,
        (sum(toss_won_count_of_each_bidder) * 100/ sum(toss_won_count_of_each_bidder) over()) as percentage
        from temp 
        group by bidder_ID order by percentage desc;  
        
        
-- 12.	find the IPL season which has a duration and max duration.
-- 	Output columns should be like the below:
--  Tournment_ID, Tourment_name, Duration column, Duration        
        
select * from ipl_tournament;
   
with temp as (
select TOURNMT_ID, TOURNMT_NAME,datediff(To_date,From_date) Duration_Column from ipl_tournament
) select TOURNMT_ID, TOURNMT_NAME,Duration_Column,first_value(Duration_Column) over(order by Duration_Column desc) from temp;


-- 13.	Write a query to display to calculate the total points month-wise for the 2017 bid year. sort the results based on total points in descending order and month-wise in ascending order.
-- Note: Display the following columns:
-- 1.	Bidder ID, 2. Bidder Name, 3. Bid date as Year, 4. Bid date as Month, 5. Total points
-- Only use joins for the above query queries.

SELECT 
    bidder_d.bidder_id Bidder_ID,
    bidder_d.BIDDER_NAME Bidder_Name,
    YEAR(Bid_date) Bid_Year,
    MONTH(bid_date) Bid_Month,
    SUM(bp.total_points) total_point
FROM
    ipl_bidding_details bd
        JOIN
    ipl_bidder_points bp ON bd.bidder_id = bp.bidder_id
        JOIN
    ipl_bidder_details bidder_d ON bp.bidder_id = bidder_d.bidder_id
WHERE
    YEAR(bid_date) = 2017
GROUP BY bidder_d.bidder_id , bidder_d.BIDDER_NAME , YEAR(Bid_date) , MONTH(bid_date)
ORDER BY total_point DESC , MONTH(bid_date) ASC;


-- 14.	Write a query for the above question using sub-queries by having the same constraints as the above question.

	SELECT 
				bidder_d.bidder_id AS Bidder_ID,
				bidder_d.BIDDER_NAME AS Bidder_Name,
				inner_query_result.Bid_Year,
				inner_query_result.Bid_Month,
				inner_query_result.total_point
FROM (
SELECT 
bd.bidder_id,
YEAR(bd.Bid_date) AS Bid_Year,
MONTH(bd.Bid_date) AS Bid_Month,
SUM(bp.total_points) AS total_point
FROM ipl_bidding_details bd
JOIN ipl_bidder_points bp ON bd.bidder_id = bp.bidder_id
WHERE YEAR(bd.Bid_date) = 2017
GROUP BY bd.bidder_id, YEAR(bd.Bid_date), MONTH(bd.Bid_date)
) AS inner_query_result
JOIN ipl_bidder_details bidder_d ON inner_query_result.bidder_id = bidder_d.bidder_id
ORDER BY inner_query_result.total_point DESC, inner_query_result.Bid_Month ASC;
            
            
-- 15.	Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
-- Output columns should be:
-- like
-- Bidder Id, Ranks (optional), Total points, Highest_3_Bidders --> columns contains name of bidder, Lowest_3_Bidders  --> columns contains name of bidder            
            
 	SELECT DISTINCT bidder_id, total_point, Highest_to_Lowest_rank
			FROM (
					select bd.bidder_id,sum(total_points) total_point, dense_rank() over(order by sum(total_points) desc) Highest_to_Lowest_rank
					from ipl_bidder_points bp join ipl_bidding_details bidding_d 
					on bp.bidder_id = bidding_d.bidder_id
					join ipl_bidder_details bd
					on bidding_d.bidder_id = bd.bidder_id
					where year(bidding_d.bid_date) = 2018
					group by bd.bidder_id
				) 
			as temp where Highest_to_Lowest_rank <= 3
			union 
			SELECT DISTINCT bidder_id, total_point, Lowest_to_Highest_rank
			FROM (
					select bd.bidder_id,sum(total_points) total_point, dense_rank() over(order by sum(total_points)) Lowest_to_Highest_rank
					from ipl_bidder_points bp join ipl_bidding_details bidding_d 
					on bp.bidder_id = bidding_d.bidder_id
					join ipl_bidder_details bd
					on bidding_d.bidder_id = bd.bidder_id
					where year(bidding_d.bid_date) = 2018
					group by bd.bidder_id
				) 
				as temp1 
				where Lowest_to_Highest_rank <= 3;           
  
 
-- 16.	Create two tables called Student_details and Student_details_backup. (Additional Question - Self Study is required)

-- Table 1: Attributes 		Table 2: Attributes
-- Student id, Student name, mail id, mobile no.	Student id, student name, mail id, mobile no.

-- Feel free to add more columns the above one is just an example schema.
-- Assume you are working in an Ed-tech company namely Great Learning where you will be inserting and modifying the details of the students in the Student details table. 
-- Every time the students change their details like their mobile number, You need to update their details in the student details table.  
-- Here is one thing you should ensure whenever the new students' details come, 
-- you should also store them in the Student backup table so that if you modify the details in the student details table, you will be having the old details safely.

-- You need not insert the records separately into both tables rather 
-- Create a trigger in such a way that It should insert the details into the Student back table when you insert the student details into the student table automatically. 
            

