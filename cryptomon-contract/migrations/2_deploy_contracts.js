var CryptomonsTrade=artifacts.require("./cryptomonsTrade.sol");
module.exports = function(deployer) {
      return deployer.deploy(CryptomonsTrade, {gas: 6700000});
}