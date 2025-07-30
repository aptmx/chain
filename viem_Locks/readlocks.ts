import { createPublicClient, http, keccak256, toHex } from 'viem'
import { sepolia } from 'viem/chains'

const contractAddress = "0xb726a48ab23bc4c40fba9d99f034b4132e0f551e"

// 创建客户端
const client = createPublicClient({
    chain: sepolia,
    transport: http(),
  })


async function main() {

    const arraySlot = 0n
    const baseSlot = BigInt(keccak256(toHex(arraySlot,{size: 32})))

    console.log(`_locks array data starts at storage slot: ${baseSlot} (hex: ${baseSlot.toString(16)})`)
    console.log(`Fetching 11 elements...\n`)

    for (let i = 0n; i < 11n; i++) {
        const structOffset = baseSlot + i * 2n;
        const slot0 = await client.getStorageAt({
            address: contractAddress,
            slot: toHex(structOffset, { size: 32 }),
        });
        const slot1 = await client.getStorageAt({
            address: contractAddress,
            slot: toHex(structOffset + 1n, { size: 32 }),
        });

        if (!slot0 || !slot1) {
            console.log(`locks[${i}]: empty`);
            continue;
        }

        const user = `0x${slot0.slice(2, 42)}`.toLowerCase();
        const startTimeHex = slot0.slice(58);
        const startTime = BigInt(`0x${startTimeHex}`);
        const amount = BigInt(slot1);

        console.log(
            `locks[${i}]: user: ${user}, startTime: ${startTime}, amount: ${amount}`
        );
    }
}

main().catch((err) => {
  console.error('❌ Error:', err)
})
