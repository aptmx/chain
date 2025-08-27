use anchor_lang::prelude::*;

// 1. 程序 ID，部署后 Anchor 会自动更新这个地址
declare_id!("5ZiwhmidBux7QKdJg5gArvaZnQBEh7ZR8Y4qT5nEpMJ1");

// 2. #[program] 宏，定义程序的主要逻辑模块
#[program]
pub mod my_counter_program {
    use super::*;

    /// 指令一：Initialize
    /// 创建一个新的计数器账户，并将其 count 初始化为 0
    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        // 从上下文中获取对计数器账户的可变引用
        let counter_account = &mut ctx.accounts.counter_account;
        // 初始化计数值
        counter_account.count = 0;
        
        // 打印一条日志，方便在交易浏览器中调试
        msg!("Counter account initialized! Current count: 0");
        
        Ok(())
    }

    /// 指令二：Increment
    /// 将指定计数器账户中的 count 值加 1
    pub fn increment(ctx: Context<Increment>) -> Result<()> {
        // 从上下文中获取对计数器账户的可变引用
        let counter_account = &mut ctx.accounts.counter_account;
        // 将计数值加 1
        counter_account.count += 1;
        
        // 打印新的计数值
        msg!("Counter incremented! New count: {}", counter_account.count);
        
        Ok(())
    }
}

// 3. #[derive(Accounts)] 宏，定义指令需要的账户上下文

/// `initialize` 指令的账户上下文
#[derive(Accounts)]
pub struct Initialize<'info> {
    /// #[account(...)] 宏用于定义对账户的约束和操作
    #[account(
        init,                         // 1. init: 创建这个账户
        payer = user,                 // 2. payer: 指定 `user` 账户为创建费用支付方
        space = 8 + 8,                // 3. space: 分配存储空间 (8字节Anchor标识符 + 8字节u64)
        seeds = [b"counter"],         // 4. seeds: 使用 "counter" 字符串作为种子派生PDA
        bump                          // 5. bump: Anchor 自动寻找并传入正确的 bump seed
    )]
    pub counter_account: Account<'info, Counter>,

    /// 定义用户账户，它必须是交易的签名者
    #[account(mut)]
    pub user: Signer<'info>,

    /// 引入 System Program，因为创建账户是它处理的
    pub system_program: Program<'info, System>,
}

/// `increment` 指令的账户上下文
#[derive(Accounts)]
pub struct Increment<'info> {
    /// 这里的约束是用来验证和加载账户的
    #[account(
        mut,                          // 1. mut: 我们需要修改这个账户的数据，所以它是可变的
        seeds = [b"counter"],         // 2. seeds: 必须提供相同的种子来找到之前创建的那个PDA
        bump                          // 3. bump: Anchor 会使用存储在账户中的 bump 值来重新派生地址并验证
    )]
    pub counter_account: Account<'info, Counter>,
}

// 4. #[account] 宏，定义账户的数据结构
/// 这是我们计数器账户实际存储在链上的数据结构
#[account]
pub struct Counter {
    pub count: u64, // 计数值，无符号64位整数
}
