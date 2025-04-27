-- View data
SELECT * FROM Matches;
SELECT * FROM deliveries;

-- 1. List all distinct seasons IPL was played
SELECT DISTINCT season FROM Matches;

-- 2. Find the number of matches played in each season
SELECT season, COUNT(*) AS total_matches
FROM Matches
GROUP BY season
ORDER BY season;

-- 3. Show top 5 venues with most matches hosted
SELECT TOP 5 venue, COUNT(*) AS matches_hosted
FROM Matches
GROUP BY venue
ORDER BY matches_hosted DESC;

-- 4. Get the player who has won the most Player of the Match awards
SELECT TOP 1 player_of_match, COUNT(*) AS awards
FROM Matches
GROUP BY player_of_match
ORDER BY awards DESC;

-- 5. List all matches where the result was a tie
SELECT * FROM Matches
WHERE result = 'tie';

-- 6. Find total runs scored by each team
SELECT batting_team, SUM(total_runs) AS total_runs
FROM deliveries
GROUP BY batting_team
ORDER BY total_runs DESC;

-- 7. Identify the top 10 highest-scoring batters
SELECT TOP 10 batter, SUM(total_runs) AS runs
FROM deliveries
GROUP BY batter
ORDER BY runs DESC;

-- 8. Calculate how many wickets each bowler has taken
SELECT bowler, COUNT(*) AS total_wickets
FROM deliveries
WHERE is_wicket = 1 
  AND dismissal_kind NOT IN ('run out', 'retired hurt', 'obstructing the field')
GROUP BY bowler
ORDER BY total_wickets DESC;

-- 9. Show match-wise total runs for a specific season (e.g., 2016)
SELECT m.id AS match_id, SUM(total_runs) AS total_runs
FROM deliveries d
JOIN matches m ON d.match_id = m.id
WHERE season = '2016'
GROUP BY m.id
ORDER BY total_runs DESC;

-- 10. Get top 5 bowlers with the best economy rate (min 200 balls bowled)
SELECT TOP 5 bowler, (SUM(total_runs) * 1.0 / COUNT(*)) AS economy_rate
FROM deliveries
GROUP BY bowler
HAVING COUNT(*) >= 200
ORDER BY economy_rate;

-- 11. Find matches where a team won by more than 100 runs
SELECT * FROM Matches
WHERE result_margin > 100
  AND result = 'runs';

-- 12. Determine the average number of boundaries (4s and 6s) per match
SELECT AVG(boundary_count) AS avg_boundaries_per_match
FROM (
    SELECT match_id, COUNT(*) AS boundary_count
    FROM deliveries
    WHERE batsman_runs IN (4, 6)
    GROUP BY match_id
) AS boundaries;

-- 13. List matches where the Player of the Match was also the top run scorer
WITH match_runs AS (
    SELECT match_id, batter, SUM(batsman_runs) AS runs
    FROM deliveries
    GROUP BY match_id, batter
),
top_scorers AS (
    SELECT match_id, batter, runs,
           RANK() OVER (PARTITION BY match_id ORDER BY runs DESC) AS rank
    FROM match_runs
)
SELECT m.id AS match_id, m.player_of_match, ts.batter, ts.runs
FROM matches m
JOIN top_scorers ts ON m.id = ts.match_id
WHERE m.player_of_match = ts.batter
  AND ts.rank = 1;

-- 14. Analyze win percentage for each team when they chose to field first
SELECT toss_winner,
       COUNT(*) AS matches_fielded,
       SUM(CASE WHEN toss_winner = winner THEN 1 ELSE 0 END) AS wins,
       CAST(SUM(CASE WHEN toss_winner = winner THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS win_percentage
FROM matches
WHERE toss_decision = 'field'
GROUP BY toss_winner
ORDER BY win_percentage DESC;

-- 15. Build a leaderboard of top 5 batters with most fifties and hundreds
WITH batter_scores AS (
    SELECT match_id, batter, SUM(batsman_runs) AS runs
    FROM deliveries
    GROUP BY match_id, batter
),
milestones AS (
    SELECT batter,
           COUNT(CASE WHEN runs BETWEEN 50 AND 99 THEN 1 END) AS fifties,
           COUNT(CASE WHEN runs >= 100 THEN 1 END) AS hundreds
    FROM batter_scores
    GROUP BY batter
)
SELECT TOP 5 batter, fifties, hundreds
FROM milestones
ORDER BY hundreds DESC, fifties DESC;
