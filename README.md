![image](https://github.com/metaforo/Ginkou/assets/5987831/c307d624-5c01-4eac-9a0f-51359c25e6c2)

# Ginkou: Game Resource Trading Tool based on AMM

Ginkou is an innovative, AMM (Automated Market Maker) based in-game resource trading tool designed to help players achieve seamless conversion and trading between resources in DOJO games and ERC20 tokens.

## Features

* Convert in-game player resources of DOJO into ERC20 tokens
* Utilize AMM to enable efficient trading of game resources on the platform
* Facilitate the trade of one resource token for another resource token
* Allow players to transfer back the converted resource tokens into corresponding in-game resources in DOJO

## How to use

### 1. Game Preparation Phase
- The administrator creates a game and provides an ERC20-like hash ( `0x02eb84e8d55ecf9ccd7409935bf0815476a4fe05a3ad61503fe4ceb980557758` ).
- The administrator, according to the game's configuration, calls the `ginkou_action.create_resource` method to generate the corresponding in-game resources and automatically deploy the related ERC20 contract.
- The administrator creates a corresponding liquidity pool in the AMM using the generated ERC20 contract address and provides an appropriate amount of liquidity.
- Players call the `player_action.create` method to create an in-game character and obtain a `player_id`.

### 2. Trading Phase
After a player obtains resource A in the game and wants to exchange it for resource B, the following steps should be taken:
- The player exchanges the in-game Resource A for the corresponding Token A by calling the `ginkou_action.withdraw` method.
- The player goes to the AMM to swap Token A for Token B.
- The player executes the `approve` method in the Token B contract.
- The player exchanges the Token B for the in-game Resource B by calling the `ginkou_action.deposit` method.