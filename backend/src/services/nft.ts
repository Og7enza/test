import { config } from '../config';

export interface MintResult {
  tokenId: string;
  contractAddress: string;
  txHash: string;
  chain: string;
}

function randHex(n: number): string {
  const h = '0123456789abcdef';
  let s = '0x';
  for (let i = 0; i < n; i++) s += h[Math.floor(Math.random() * 16)];
  return s;
}

/**
 * Mint NFT « gas-free » : le wallet sponsor (backend) paie le gas.
 * - Réel quand POLYGON_RPC_URL + MINTER_PRIVATE_KEY + NFT_CONTRACT_ADDRESS sont
 *   fournis (ethers, voir TODO ci-dessous).
 * - Sinon : mint SIMULÉ (mêmes champs, pour tester de bout en bout).
 */
export async function mintNft(args: {
  matricule: string;
  sha256: string;
  to?: string;
  metadataUrl?: string;
}): Promise<MintResult> {
  if (config.nftEnabled) {
    // TODO (réel) :
    //   const { ethers } = await import('ethers');
    //   const provider = new ethers.JsonRpcProvider(config.polygonRpcUrl);
    //   const wallet = new ethers.Wallet(config.minterPrivateKey, provider);
    //   const abi = ['function mintTo(address to, string uri) returns (uint256)'];
    //   const contract = new ethers.Contract(config.nftContract, abi, wallet);
    //   const tx = await contract.mintTo(args.to ?? wallet.address, args.metadataUrl ?? '');
    //   const receipt = await tx.wait();
    //   return { tokenId: '...', contractAddress: config.nftContract, txHash: receipt.hash, chain: config.chain };
  }
  return {
    tokenId: String(Math.floor(Math.random() * 1e9)),
    contractAddress:
      config.nftContract || '0xMOCK0000000000000000000000000000000000',
    txHash: randHex(64),
    chain: config.chain,
  };
}
