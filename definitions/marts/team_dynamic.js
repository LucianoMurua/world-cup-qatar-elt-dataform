constants.SEMIFINALISTS.forEach((team) => {
  const slug = team.toLowerCase().replace(/[^a-z0-9]+/g, "_");
  const tableName = `mart_${slug}_players`;

  // 1) Tabla con la plantilla completa del equipo
  publish(tableName, {
    type: "table",
    tags: ["country"],
    description: `Full squad stats for ${team}.`,
    assertions: {
      uniqueKey: ["player_name"],
      nonNull: ["player_name", "position"],
      rowConditions: ["position IN ('GK', 'DF', 'MF', 'FW')"]
    }
  }).query((ctx) => `
    SELECT
      team, player_name, position, club, jersey_number, birth_date,
      appearances, goals, assists,
      dribbles_per_90, interceptions_per_90, tackles_per_90,
      duels_won_per_90, save_pct, clean_sheet_pct
    FROM ${ctx.ref("stg_players")}
    WHERE team = '${team}'
  `);

  // 2) Vista con los 5 jugadores más decisivos (goles + asistencias)
  publish(`vw_${slug}_top_contributors`, {
    type: "view",
    tags: ["country"],
    description: `Top 5 goal contributors (goals + assists) for ${team}.`
  }).query((ctx) => `
    SELECT
      player_name, position, goals, assists,
      IFNULL(goals, 0) + IFNULL(assists, 0) AS goal_contributions
    FROM ${ctx.ref(tableName)}
    WHERE goals IS NOT NULL OR assists IS NOT NULL
    ORDER BY goal_contributions DESC, player_name
    LIMIT 5
  `);

  // 3) Assertion generada: la tabla debe tener tantas filas como squad_size
  assert(`assert_${slug}_rows_match_squad_size`, {
    tags: ["country"]
  }).query((ctx) => `
    SELECT s.team, s.squad_size, p.n AS rows_in_team_table
    FROM ${ctx.ref("mart_team_summary")} AS s
    CROSS JOIN (SELECT COUNT(*) AS n FROM ${ctx.ref(tableName)}) AS p
    WHERE s.team = '${team}' AND s.squad_size != p.n
  `);
});