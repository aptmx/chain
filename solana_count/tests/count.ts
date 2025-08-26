// 导入 Anchor 和其他必要的库
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { MyCounterProgram } from "../target/types/my_counter_program";
import { assert } from "chai";

describe("my-counter-program", () => {
  // --- 测试设置 ---

  // 配置 Anchor 使用本地集群的 Provider
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  // 从 IDL 中加载我们的链上程序，以便在客户端与之交互
  const program = anchor.workspace.MyCounterProgram as Program<MyCounterProgram>;
  
  // 这是我们将要创建的计数器账户的 PDA 地址。
  // 我们在测试开始前先计算出来，以便在多个测试用例中使用。
  let counterPda: anchor.web3.PublicKey;

  // --- 测试用例 ---

  it("Derives the counter PDA correctly!", async () => {
    // 这是一个准备步骤，计算出计数器账户的 PDA 地址。
    // 这与我们在讨论中提到的客户端“生成地址”的步骤完全对应。
    const [pda, bump] = anchor.web3.PublicKey.findProgramAddressSync(
      // 使用和链上程序完全相同的种子
      [Buffer.from("counter")],
      program.programId
    );
    
    // 将计算出的地址保存在变量中，以便后续测试使用
    counterPda = pda;

    console.log("Counter PDA address:", counterPda.toBase58());
    console.log("Bump seed:", bump);

    // 断言地址不为空，确保计算成功
    assert.ok(counterPda);
  });

  it("Initializes the counter account!", async () => {
    // --- 调用 initialize 指令 ---
    // 我们调用 initialize 指令来创建并初始化计数器账户。
    const tx = await program.methods
      .initialize()
      .accounts({
        counterAccount: counterPda,      // 传入我们计算出的PDA地址
        user: provider.wallet.publicKey, // 指定费用支付方（也就是我们的钱包）
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc(); // 发送并确认交易

    console.log("Initialize transaction signature", tx);

    // --- 验证结果 ---
    // 从链上获取刚刚创建的账户的数据
    const accountData = await program.account.counter.fetch(counterPda);

    // 使用断言来验证 count 字段是否被正确初始化为 0
    // 注意：链上返回的数字是 BN (BigNumber) 类型，需要用 .toNumber() 转换
    assert.equal(accountData.count.toNumber(), 0, "Count should be initialized to 0");
    console.log("Account count after initialization:", accountData.count.toNumber());
  });

  it("Increments the counter account!", async () => {
    // --- 调用 increment 指令 ---
    // 这个测试假设 initialize 已经成功执行
    const tx = await program.methods
      .increment()
      .accounts({
        counterAccount: counterPda, // 传入同一个 PDA 地址
      })
      .rpc();

    console.log("Increment transaction signature", tx);

    // --- 验证结果 ---
    // 再次从链上获取账户数据
    const accountData = await program.account.counter.fetch(counterPda);

    // 断言 count 字段是否被正确地增加了 1
    assert.equal(accountData.count.toNumber(), 1, "Count should be incremented to 1");
    console.log("Account count after increment:", accountData.count.toNumber());
  });

  it("Increments the counter account again!", async () => {
    // 我们可以多次调用 increment
    const tx = await program.methods
      .increment()
      .accounts({
        counterAccount: counterPda,
      })
      .rpc();
  
    console.log("Second increment transaction signature", tx);
  
    // --- 验证结果 ---
    const accountData = await program.account.counter.fetch(counterPda);
  
    // 断言 count 是否为 2
    assert.equal(accountData.count.toNumber(), 2, "Count should be incremented to 2");
    console.log("Account count after second increment:", accountData.count.toNumber());
  });
});