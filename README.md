# Sonic Robo Blast 2

## Pack metadata

- **Game:** Sonic Robo Blast 2
- **Crowd Control game ID:** `SonicRoboBlast2`
- **Connector:** `FileConnector`

This pack connects Crowd Control to **Sonic Robo Blast 2** through the bundled
`SL_CrowdControl.pk3` Lua mod. It uses a file-based connector rather than a
network socket.

## Requirements

- Crowd Control with the **Sonic Robo Blast 2** effect pack.
- Sonic Robo Blast 2.
- `SL_CrowdControl.pk3`, included in this directory.

## Setup

1. Select the Sonic Robo Blast 2 effect pack in Crowd Control and set its game
   path to the Sonic Robo Blast 2 executable.
2. Load `SL_CrowdControl.pk3` in Sonic Robo Blast 2 using the game's normal
   PK3 loading process.
3. Enter a map. The mod creates its connector files and Crowd Control can then
   communicate with the game.

Most effects are intended to run while a map is active.

## Connection behavior

The mod and pack exchange messages through files in the game's local
`luafiles\client\crowd_control` directory:

- `connector.txt` signals readiness;
- `input.txt` carries requests from Crowd Control to the mod; and
- `output.txt` carries responses back to Crowd Control.

The mod writes `READY` to the readiness file once its connection logic is
running. Timed effects also track whether their individual readiness checks
remain valid.

## Troubleshooting

- **The session never connects:** verify that the correct executable path is
  configured and that `SL_CrowdControl.pk3` was loaded into the running game.
  Then check for `connector.txt` under `luafiles\client\crowd_control`.
- **Effects do not run:** enter an active map and retry; the original pack
  notes that most effects only work in a map.
- **File access errors:** ensure the game can create and update
  `input.txt`/`output.txt` in its local `luafiles` directory.

## Building the PK3

For contributors, open the `SL_CrowdControl` folder in
[SLADE](http://slade.mancubus.net/index.php?page=downloads) and use
**Archive → Build Archive** to export a PK3. Additional PK3 background is
available from the <https://wiki.srb2.org/wiki/PK3>.
