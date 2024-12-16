import {HardhatRuntimeEnvironment} from "hardhat/types";
import {DeployFunction} from "hardhat-deploy/types";

const func: DeployFunction = async function(
    hre: HardhatRuntimeEnvironment
) {
    const {getNamedAccounts, deployments, network} = hre;
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();

    console.log('deployer',deployer)
    log("Deploying Token...")
    const token = await deploy("ReinvestmentManager",{
        from: deployer,
        log: true,
        autoMine: true,
        skipIfAlreadyDeployed: false,
    });
    log(`Deployed token to address ${token.address}`)
};

export default func;
func.tags = ["rm"];