using CrowdControl.Common;
using JetBrains.Annotations;

namespace CrowdControl.Games.Packs.SonicRoboBlast2;

[UsedImplicitly]
class SonicRoboBlast2 : FileEffectPack
{
    public override string ReadFile => "/luafiles/client/crowd_control/output.txt"; //GameFolder + "/luafiles/client/crowd_control/output.txt";
    public override string WriteFile => "/luafiles/client/crowd_control/input.txt"; //GameFolder + "/luafiles/client/crowd_control/input.txt";
    public static string ReadyCheckFile = "/luafiles/client/crowd_control/connector.txt"; //GameFolder + "/luafiles/client/crowd_control/connector.txt";

    public override Game Game { get; } = new("Sonic Robo Blast 2", "SonicRoboBlast2", "PC", ConnectorType.FileConnector);

    public override EffectList Effects
    {
        get
        {
            List<Effect> effects =
            [
                new Effect("Spawn Bumper", "bumper")
                    { Price = 10, Description = "Spawns a bumper in the player's way." },
                new Effect("Give Rings", "giverings")
                    { Price = 1, Quantity = 99, Description = "Give the player some rings." },
                new Effect("Kill", "kill") { Price = 200, Description = "Take a life from the player." },
                new Effect("Slap", "slap") { Price = 25, Description = "Give the player a good slap" },
                new Effect("Give Speedshoes", "sneakers")
                    { Price = 25, Description = "Give the player a pair of speed shoes. Gotta go fast!" },
                new Effect("Give Invincibility", "invulnerability")
                    { Price = 25, Description = "Give the player invincibility. How nice of you." },

                new Effect("Disable Jump", "nojump")
                {
                    Duration = 10, Price = 50, Category = "Controls",
                    Description = "Disables the player's jump button."
                },
                new Effect("Disable Spin", "nospin")
                {
                    Duration = 10, Price = 50, Category = "Controls",
                    Description = "Disables the player's spin button."
                },
                new Effect("Invert Controls", "invertcontrols")
                {
                    Duration = 15, Price = 50, Category = "Controls", Description = "Inverts the player's controls."
                },

                new Effect("Spawn Crawla", "crawla")
                    { Price = 10, Category = "Enemies", Description = "Spawns a Crawla around the player." },
                new Effect("Spawn Rosy", "rosy")
                    { Price = 10, Category = "Enemies", Description = "Spawns Amy to hug the player." },
                new Effect("Spawn Crawla Commander", "commander")
                {
                    Price = 50, Category = "Enemies", Description = "Spawns a Crawla Commander around the player."
                },

                new Effect("Give Pity Shield", "pityshield")
                    { Price = 10, Category = "Shields", Description = "Grants the player a basic shield." },
                new Effect("Give Fire Shield", "fireshield")
                    { Price = 10, Category = "Shields", Description = "Grants the player a fire shield." },
                new Effect("Give Bubble Shield", "bubbleshield")
                {
                    Price = 10, Category = "Shields", Description = "Grants the player a bubble shield. BWAOH"
                },
                new Effect("Give Lightning Shield", "lightningshield")
                {
                    Price = 10, Category = "Shields", Description = "Grants the player a lightning shield."
                },

                new Effect("Change to Sonic", "changesonic")
                    { Price = 10, Category = "Characters", Description = "Sets the player character to Sonic." },
                new Effect("Change to Tails", "changetails")
                    { Price = 10, Category = "Characters", Description = "Sets the player character to Tails." },
                new Effect("Change to Knuckles", "changeknuckles")
                {
                    Price = 10, Category = "Characters", Description = "Sets the player character to Knuckles."
                },
                new Effect("Change to Amy", "changeamy")
                    { Price = 10, Category = "Characters", Description = "Sets the player character to Amy." },
                new Effect("Change to Fang", "changefang")
                    { Price = 10, Category = "Characters", Description = "Sets the player character to Fang." },
                new Effect("Change to Metal Sonic", "changemetal")
                {
                    Price = 10, Category = "Characters", Description = "Sets the player character to Metal Sonic."
                },
                new Effect("Change to Random Character", "changerandom")
                {
                    Price = 10, Category = "Characters",
                    Description = "Sets the player character to a random character."
                },
                new Effect("Emote Heart", "emoteheart")
                {
                    Price = 1, Category = "Emotes",
                    Description = "Send the player some lovely encouragement."
                },
                new Effect("Emote Pog", "emotepog")
                    { Price = 1, Category = "Emotes" },
                new Effect("Emote No Way", "emotenoway") 
                    { Price = 1, Category = "Emotes" },
                new Effect("Bonus Fang", "bonusfang")
                {
                    Price = 100, Inactive = true,
                    Description = "(Unstable?) Fang takes the player on a little journey."
                },
                new Effect("Squish Player", "squish")
                {
                    Duration = 15, Price = 5,
                    Description = "Squish the player for a little while."
                },
                new Effect("Tall Player", "tall")
                {
                    Duration = 15, Price = 5,
                    Description = "Make the player tall for a little while."
                }
            ];
            return effects;
        }
    }

    public SonicRoboBlast2(UserRecord player, Func<CrowdControlBlock, bool> responseHandler, Action<object> statusUpdateHandler) : base(player, responseHandler, statusUpdateHandler)
    {
    }

    protected override GameState GetGameState()
    {
        return IsReady() ? GameState.Ready : GameState.Paused;
    }

    static bool IsReady()
    {
        if (File.Exists(ReadyCheckFile))
        {
            string readyTest = File.ReadAllText(ReadyCheckFile);

            if (String.IsNullOrEmpty(readyTest))
            {
                return false;
            }
            else
            {
                return true;
            }
        }
        else
        {
            return false;
        }

    }
}
