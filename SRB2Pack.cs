using CrowdControl.Common;
using JetBrains.Annotations;
using System;
using System.IO;
using System.Collections.Generic;

namespace CrowdControl.Games.Packs.SRB2
{
    [UsedImplicitly]
    class SRB2 : FileEffectPack
    {
        public override string ReadFile => "/luafiles/client/crowd_control/output.txt"; //GameFolder + "/luafiles/client/crowd_control/output.txt";
        public override string WriteFile => "/luafiles/client/crowd_control/input.txt"; //GameFolder + "/luafiles/client/crowd_control/input.txt";
        public static string ReadyCheckFile = "/luafiles/client/crowd_control/connector.txt"; //GameFolder + "/luafiles/client/crowd_control/connector.txt";

        public override Game Game => new("Sonic Robo Blast 2", "SRB2", "PC", ConnectorType.FileConnector);

        public override EffectList Effects
        {
            get
            {
                List<Effect> effects = new List<Effect>
                {
                    new Effect("Spawn Bumper", "bumper") { Price = 10, Description = "Spawns a bumper in the player's way." },
                    new Effect("Give Rings", "giverings") { Price = 1, Quantity = 99, Description = "Give the player some rings." },
                    new Effect("Give Life", "givelife") { Price = 100, Description = "Give the player an extra life." },
                    new Effect("Kill", "kill") { Price = 200, Description = "Take a life from the player." },
                    new Effect("Slap", "slap") { Price = 25, Description = "Give the player a good slap" },

                    new Effect("Disable Jump", "nojump") { Duration = 15, Price = 50, Category = "Controls", Description = "Disables the player's jump button." },
                    new Effect("Disable Spin", "nospin") { Duration = 15, Price = 50, Category = "Controls", Description = "Disables the player's spin button." },
                    new Effect("Invert Controls", "invertcontrols") { Duration = 15, Price = 50, Category = "Controls", Description = "Inverts the player's controls." },

                    new Effect("Change to Sonic", "changesonic") { Price = 10, Category = "Characters", Description = "Sets the player character to Sonic." },
                    new Effect("Change to Tails", "changetails") { Price = 10, Category = "Characters", Description = "Sets the player character to Tails." },
                    new Effect("Change to Knuckles", "changeknuckles") { Price = 10, Category = "Characters", Description = "Sets the player character to Knuckles." },
                    new Effect("Change to Amy", "changeamy") { Price = 10, Category = "Characters", Description = "Sets the player character to Amy." },
                    new Effect("Change to Fang", "changefang") { Price = 10, Category = "Characters", Description = "Sets the player character to Fang." },
                    new Effect("Change to Metal Sonic", "changemetal") { Price = 10, Category = "Characters", Description = "Sets the player character to Metal Sonic." },
                    new Effect("Change to Random Character", "changerandom") { Price = 10, Category = "Characters", Description = "Sets the player character to a random character." },
                };
                return effects;
            }
        }

        public SRB2(UserRecord player, Func<CrowdControlBlock, bool> responseHandler, Action<object> statusUpdateHandler) : base(player, responseHandler, statusUpdateHandler)
        {
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
}
