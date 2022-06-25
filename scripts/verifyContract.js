/**
 *  This script will calculate the constructor arguments for the `verify` function and call it.
 *  You can use this script to verify the contract on etherscan.io.
 */

 require('@nomiclabs/hardhat-etherscan')
 const hre = require('hardhat')
 const { MerkleTree } = require('merkletreejs')
 const keccak256 = require('keccak256')
 const whitelist = require('./whitelist.js')
 const giveawaylist = require('./giveaway.js')
 
 const BASE_URI = 'ipfs://QmQSfWwHD27sYjqJwrted6dyw87ScZMRffqTk5WZYujLdJ/';
 const proxyRegistryAddressRinkeby = '0xf57b2c51ded3a29e6891aba85459d600256cf317'
 const proxyRegistryAddressMainnet = '0xa5409ec958c83c3f309868babaca7c86dcb077c1'
 
 async function main() {
   // Calculate merkle root from the whitelist array
  const leafNodes = whitelist.map((addr) => keccak256(addr))
  const leafNodesGA = giveawaylist.map((addr) => keccak256(addr))
  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })
  const merkleTreeGA = new MerkleTree(leafNodesGA, keccak256, { sortPairs: true })
  const root = merkleTree.getRoot()
  const rootGA = merkleTreeGA.getRoot()
 
   await hre.run('verify:verify', {
     address: '0xeAa7036145D80cC1e847BD2049C0F55c3a7C54b7', // Deployed contract address
     constructorArguments: [BASE_URI, root, rootGA, proxyRegistryAddressRinkeby]
   })
 }
 
 // We recommend this pattern to be able to use async/await everywhere
 // and properly handle errors.
 main()
   .then(() => process.exit(0))
   .catch((error) => {
     console.error(error)
     process.exit(1)
   })