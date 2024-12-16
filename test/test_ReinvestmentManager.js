const { expect } = require("chai");
const { ethers } = require("hardhat")
const { BigNumber } = require("ethers");

describe("ReinvestmentManager and AssetNFT", function () {
  let rm, curentNFTAsset;
  let owner, user1, user2, assetVault;

  let userIDs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  let balances = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];
  let salts = ["salt1", "salt2", "salt3", "salt4", "salt5", "salt6", "salt7", "salt8", "salt9", "salt10"];

  let userIDsSetSecond = [11, 12, 13, 14, 15];
  let saltsSetSecond = ["salt11", "salt12", "salt13", "salt14", "salt15"];
  let balancesSetSecond = [1100, 1200, 1300, 1400, 1500];

  before(async function () {
    // Get signers
    [owner, user1, user2, assetVault] = await ethers.getSigners();

    // Get the contract factories
    rm = await ethers.deployContract("ReinvestmentManager");

  });

  describe("Deploying contract", function () {
    it("Should set the correct admin, i.e. deployer is equal to the admin", async function () {
      const admin = await rm.admin()
      const ownerAddress = owner.address;
      expect(admin).to.equal(ownerAddress);
    });

    it(`Should create the initial reinvestment period with following parameters:
      1. ID = 1
      2. start != 0
      3. end = 0
      4. rate = 1000
      5. currentAsset = address of NFT contract
      `, async function () {

      const period = await rm.reinvestmentPeriod();
      expect(period.ID).to.equal(1);
      expect(period.start).not.equal(0);
      expect(period.end).to.equal(0);
      expect(period.rate).to.equal(1000);
      // updating current Asset's information
      curentNFTAsset = period.currentAsset;
      expect(curentNFTAsset).not.equal(null);
    });

    describe("Interacting with deployed contract of NFTAsset", function () {

      it("Taking instance of the deployed contract", async function () {
        deployedAssetNFT = await ethers.getContractAt("AssetNFT", curentNFTAsset);
      });

      it("Verifing the batch size", async function () {
        expect(await deployedAssetNFT._batch_size()).to.equal(1000);
      });

      it("Verifing the reinvestment manager", async function () {
        expect(await deployedAssetNFT.reinvestmentManager()).to.equal(rm.target);
      });

      it("Checking Vault information", async function () {
        expect(await deployedAssetNFT.vault()).to.equal(owner.address);
      });
    });
  });

  describe("User Batch Operations, adding users", function () {
    it("Should add a batch of users, adding 10 users", async function () {
      // Adding users
      await rm.addUserBatch(userIDs, salts, balances)

      for (let i = 0; i < userIDs.length; i++) {
        const userId = i + 1;  // User IDs are 1 through 10
        const expectedBalance = balances[i];

        const userBalance = await rm.userBalance(userId);
        expect(userBalance).to.equal(expectedBalance);
      }
    });

    // checking added users' length
    it('Checking the number of users length', async function () {
      expect(await rm.getUserLength()).to.equal(userIDs.length);
    });

    it("Should not allow adding an already added user", async function () {
      const userIDs = [1];
      const salts = ["salt1"];
      const balances = [1000];

      await expect(
        rm.addUserBatch(userIDs, salts, balances)
      ).to.be.revertedWith("user is already added");
    });


    it("Verifing the meta Info for 1 user", async function () {
      expect((await deployedAssetNFT.assetMetadata(1)).userID).to.equal(1);
      expect((await deployedAssetNFT.assetMetadata(1)).salt).to.equal('salt1');
      expect((await deployedAssetNFT.assetMetadata(1)).amount).to.equal(0);
      expect((await deployedAssetNFT.assetMetadata(1)).savingsBalance).to.equal(100);
    });

  });

  describe("Reinvest Savings", function () {
    it("Should reinvest savings and mint new assets", async function () {
      await rm.reinvestSavings()

      const period = await rm.reinvestmentPeriod();
      expect(period.ID).to.equal(2);
      expect(period.start).not.equal(0);
      expect(period.end).to.equal(0);
      expect(period.rate).to.equal(1000);
      // updating current Asset's information
      curentNFTAsset = period.currentAsset;
      expect(curentNFTAsset).not.equal(null);

      for (let i = 0; i < userIDs.length; i++) {
        const userId = i + 1;  // User IDs are 1 through 10
        const expectedBalance = balances[i];

        const userBalance = await rm.userBalance(userId);
        expect(userBalance).to.be.greaterThan(expectedBalance);
      }
    });
  });

  describe("Second Phase", function () {
    it("Adding second set of users, checking length and corresponding balances", async function () {
      await rm.addUserBatch(userIDsSetSecond, saltsSetSecond, balancesSetSecond)
      for (let i = 0; i < userIDsSetSecond.length; i++) {
        const userId = i;  // User IDs are 1 through 10
        const expectedBalance = balancesSetSecond[i];
        const userBalance = await rm.userBalance(userIDsSetSecond[userId]);
        expect(userBalance).to.equal(expectedBalance);
      }
    });

    it("Checking total number of users", async function () {
      const totalUsers = await rm.getUserLength();
      expect(totalUsers).to.equal(userIDs.length + userIDsSetSecond.length);
    });

    it("getting user's portfolio", async function () {
      const portfolio = await rm.userPortfolio(11, 0);
      expect(portfolio[0][5]).to.equal(curentNFTAsset);
    });
  });

  describe("Transfer User Batch", function () {
    it("Should transfer a batch of users' assets", async function () {
      const userIDs = [1, 2];

      await rm.transferUserBatch(userIDs, user1.address)
      // Check that user1's balance is now zero
      const user1Balance = await rm.userBalance(1);
      expect(user1Balance).to.equal(0);
      const user2Balance = await rm.userBalance(2);
      expect(user2Balance).to.equal(0);
    });
  });

  it("Should revert if non-admin tries to set rate or asset price", async function () {
    await expect(rm.connect(user1).setRate(2000)).to.be.revertedWith("no permission");
    await expect(rm.connect(user1).setAssetPrice(2000)).to.be.revertedWith("no permission");
  });
});