-- IPL Match Analytics (2008–2024)

--Beginner: Data Understanding & Summary (Q1–Q5) */

/* Q1) How many matches were played in total and across each season? */
-- (i) Total matches played in ipl till 2024.
select count(mid) as total_matches from matches

-- (ii) Total matches played per season.
select season, count(mid) as total_matches from matches 
group by season
order by season

/* Q2) Which teams played the most matches? */
select team, count(*)
from(
 select team1 as team from matches
 union all 
 select team2 as team from matches
) all_teams
group by team
order by count(*) desc

/* Q3) Which venues hosted the most matches? */
select venue, count(venue) as total_matches from matches
group by venue 
order by count(venue) desc

/* Q4) Which cities have seen the most IPL action? */
select city, count(city) as total_matches from matches
group by city 
order by count(city) desc

/* Q5) What is the frequency of each match type (League, Qualifier, Final, etc.)? */
select match_type, count(match_type) as total_matches from matches
group by match_type
order by total_matches desc

-- Intermediate: Toss & Match Analysis (Q6–Q12)
/* Q6) Which team has won the toss most often?*/
select toss_winner as team, count(toss_winner) as number_of_wins from matches 
group by team
order by number_of_wins desc

/* Q7) How often did toss winners win the match? */
select count(*) as total_matches,
sum(case when toss_winner = winner then 1 else 0 end) as toss_win_and_match_win,
round(sum(case when toss_winner = winner then 1 else 0 end)*100 / count(*), 2) as toss_win_effect_percet
from matches

/* Q8) What’s the overall win percentage for toss winners across all seasons?*/
select season, COUNT(*) AS total_matches,
sum(case when toss_winner = winner then 1 else 0 end) as toss_win_and_match_win,
round(sum(case when toss_winner = winner then 1 else 0 end)*100 / count(*), 2) as toss_win_effect_percent
from matches
group by season
order by season desc

/* Q9) Do teams that chose to bat after winning the toss have a higher win rate than those who chose to field?*/
select toss_decision, count(*) as total_matches,
sum(case when toss_winner= winner then 1 else 0 end) as toss_win_and_match_win,
round(100.00*(sum(case when toss_winner= winner then 1 else 0 end))/count(*),2) as toss_decision_effect_percent
from matches
group by toss_decision
order by toss_decision_effect_percent desc

/* Q10) Which toss decision (bat/field) is more successful overall and by season?*/
-- (i) Overall toss decision
select toss_decision, count(*) as total_decisions,
sum(case when toss_winner= winner then 1 else 0 end) as match_wins,
round(100.00*sum(case when toss_winner= winner then 1 else 0 end)/count(*),2) as win_percent
from matches 
group by toss_decision
order by win_percent desc

-- (ii) By season
select season, toss_decision, count(*) as total_decisions,
sum(case when toss_winner= winner then 1 else 0 end) as match_wins,
round(100.00*sum(case when toss_winner= winner then 1 else 0 end)/count(*),2) as win_percent
from matches
group by toss_decision, season
order by season, win_percent desc

/* Q11) List matches where the toss winner lost the match (tactical decision analysis).*/
select*from matches
where toss_winner <> winner

-- or just like the toss winner question if we want the number of matches lost and it's percent we can use the following query
select count(*) as total_matches,
sum(case when toss_winner != winner then 1 else 0 end) as toss_win_and_match_lost,
round(sum(case when toss_winner != winner then 1 else 0 end)*100 / count(*), 2) as toss_win_effect_percet
from matches

/* Q12) Which teams are most successful while chasing (result1 = 'wickets')? */
select winner, count(*) as chases from matches
where result1='wickets'
group by winner
order by chases desc

--  Performance Patterns (Q13–Q17)
/* Q13) Top 10 most successful teams by total match wins. */
select winner, count(*) as total_wins
from matches
where winner is not null
group by winner
order by total_wins desc
limit 10

/* Q14) Top 10 players with the most “Player of the Match” awards. */
select player_of_match as player_name, count(*) as total_awards from matches
group by player_name
order by total_awards desc
limit 10

/* Q15) Which stadiums are more chase-friendly vs. defend-friendly (by win result type)? */
select venue, result1, count(result1) as results from matches
where result1 in ('runs','wickets')
group by venue, result1
order by venue, results desc

/* Q16) Average result margin when winning by runs vs wickets? */
select result1 as result_type, round(avg(result_margin) :: numeric ,2) as avg_margin from matches
where result1 in ('runs','wickets') 
group by result1

/* Q17) Which teams win most often with large margins (e.g., 50+ runs or 8+ wickets)? */
select winner as team_name, count(*) as number_of_big_wins from matches
where(result1='runs' and result_margin > 50
or
result1='wickets' and result_margin>8
)
group by winner
order by count(*) desc

-- Advanced SQL Concepts (Q18–Q25)
/* Q18) Use a window function to rank teams by number of wins each season. */
select season, winner as team, total_wins,
rank() over (partition by season order by total_wins desc) as season_rank
from (
select season, winner , count(*) as total_wins from matches 
where winner is not null
group by season, winner
) as season_wise_wins
order by season, season_rank

/* Q19) Find the top 3 “Player of the Match” winners per season using DENSE_RANK(). */
with ranked_awards as(
select season, player_of_match, count(*) as awards,
dense_rank() over (partition by season order by count(*) desc) as season_rank
from matches
where player_of_match is not null
group by season, player_of_match
)
select*from ranked_awards 
where season_rank<=3
order by season, season_rank

/* Q20) Create a running total of wins for each team across seasons. */
with team_wins as (
    select season, winner as team, count(*) as season_wins
    from matches
    where winner is not null
    group by season, winner
	order by season, season_wins desc
)
select 
    season, team, season_wins,
    sum(season_wins) over (partition by team order by season) as cumulative_wins
from team_wins
order by team, season;

/* Q21) Find the most unpredictable venue (max number of unique winners). */
select venue, count(distinct winner) as distinct_wins from matches
where winner is not null
group by venue
order by distinct_wins desc

/* Q22) Analyze super over frequency by season and team. */
-- Per Season
select season, count(super_over) as super_overs from matches
where super_over= 'Y'
group by season
order by super_overs desc

-- Per Team
select teams, count(*) as super_over_played
from (
select team1 as teams from matches where super_over='Y'
union all 
select team2 as teams from matches where super_over='Y'
)
group by teams
order by super_over_played desc

/* Q23) Create a match-level flag: CASE WHEN toss_winner = winner THEN 'Toss Impact' ELSE 'No Impact' and analyze the proportion. */
select
case when toss_winner= winner then 'Toss Impact'
else 'No Impact'
end as toss_effect,
count(*) as match_count,
round(100*count(*)/(select count(*) from matches),2) as percent_share
from matches 
group by toss_effect

/* Q24) Which umpires have officiated the most matches — and who appears in the most finals? */
-- For most appearances 
select umpire, count(*) as total_matches_officiated 
from (
select umpire1 as umpire from matches 
union all 
select umpire2 as umpire from matches
)
group by umpire 
order by total_matches_officiated desc

-- Most ipl finals
select umpire, count(*) as final_matches_officiated
from (
select umpire1 as umpire from matches where match_type='Final'
union all 
select umpire2 as umpire from matches where match_type='Final'
)
group by umpire 
order by final_matches_officiated desc

