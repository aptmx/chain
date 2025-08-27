import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { MyCounterProgram } from "../target/types/my_counter_program";
import { assert } from "chai";

describe("my_counter_program", () => {
  // --- 配置客户端 ---
  // 使用 Anchor 自动配置的环境，它会从 Anchor.toml 读取配置
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  // 从 IDL 生成的程序客户端
  const program = anchor.workspace.MyCounterProgram as Program<MyCounterProgram>;

  // 我们需要一个密钥对来支付交易费和创建账户
  // Anchor 会自动使用 provider.wallet.publicKey
  const user = provider.wallet;

  // --- 推导 PDA (Program Derived Address) ---
  // 这是我们将要创建的计数器账户的地址。
  // 它由 "counter" 这个种子和程序 ID 派生而来，确保了地址的唯一性和确定性。
  const [counterPda, bump] = anchor.web3.PublicKey.findProgramAddressSync(
    [Buffer.from("counter")], // 使用与合约中相同的种子
    program.programId
  );

  // --- 测试用例 ---

  it("Is initialized!", async () => {
    // --- 1. 调用 initialize 指令 ---
    console.log("正在调用 'initialize' 指令...");
    console.log("计数器账户 PDA:", counterPda.toBase58());
    console.log("用户 (payer):", user.publicKey.toBase58());

    const tx = await program.methods
      .initialize()
      .accounts({
        counterAccount: counterPda,
        user: user.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    console.log("Initialize 交易签名:", tx);

    // --- 验证结果 ---
    // 获取新创建的账户数据
    const account = await program.account.counter.fetch(counterPda);
    console.log("链上计数器的初始值:", account.count.toString());

    // 断言：验证 count 是否为 0
    assert.ok(account.count.toNumber() === 0, "计数器初始值应为 0");
  });

  it("Incremented the count!", async () => {
    // --- 2. 调用 increment 指令 ---
    console.log("正在调用 'increment' 指令...");

    const tx = await program.methods
      .increment()
      .accounts({
        counterAccount: counterPda,
      })
      .rpc();

    console.log("Increment 交易签名:", tx);

    // --- 验证结果 ---
    // 再次获取账户数据
    const account = await program.account.counter.fetch(counterPda);
    console.log("链上计数器的当前值:", account.count.toString());

    // 断言：验证 count 是否为 1
    assert.ok(account.count.toNumber() === 1, "计数器值应为 1");

    // --- 再次调用 increment ---
    console.log("\n再次调用 'increment' 指令...");
    await program.methods
      .increment()
      .accounts({ counterAccount: counterPda })
      .rpc();

    const accountAfterSecondIncrement = await program.account.counter.fetch(counterPda);
    console.log("第二次 increment 后，链上计数器的值:", accountAfterSecondIncrement.count.toString());
    assert.ok(accountAfterSecondIncrement.count.toNumber() === 2, "计数器值应为 2");
  });
});