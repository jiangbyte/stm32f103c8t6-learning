/**
 * ============================================================================
 * 案例 01 · PA0 软件 PWM 呼吸灯
 * ============================================================================
 */
#include "stm32f1xx.h" /* 引入 STM32F1 CMSIS 头文件，提供 RCC/GPIO 等寄存器定义 */

/**
 * 粗延时：空转指定拍数，时长随内核时钟变化，仅用于演示。
 * @param count 循环次数；声明为 volatile，防止编译器把空循环优化掉。
 */
static void delay_cycles(volatile uint32_t count)
{
  while (count--) { /* 每轮减一，直到减到 0 后退出 */
    __NOP();       /* 插入一条空操作指令，消耗少量时钟周期 */
  }
}

/**
 * 软件 PWM 一个周期：先高电平 on 拍，再低电平 (period-on) 拍。
 * @param on     高电平持续拍数（占空比分子）
 * @param period 一个 PWM 周期总拍数（占空比分母）
 */
static void pwm_cycle(uint32_t on, uint32_t period)
{
  GPIOA->BSRR = (1u << 0);       /* 写 BSRR 低 16 位：原子置位 PA0=1，点亮 LED */
  delay_cycles(on);              /* 保持高电平 on 个空转拍 */
  GPIOA->BRR = (1u << 0);        /* 写 BRR：原子清零 PA0=0，熄灭 LED */
  delay_cycles(period - on);     /* 保持低电平，凑满一个 period 周期 */
}

/**
 * 配置 PA0 为推挽输出，并以软件 PWM 做呼吸灯（高电平点亮）。
 */
int main(void)
{
  /* 1. 使能 GPIOA 外设时钟：未开时钟则读写 GPIOA 寄存器无效 */
  RCC->APB2ENR |= RCC_APB2ENR_IOPAEN; /* APB2ENR 位置位 IOPAEN，打开 GPIOA 时钟 */

  /* 2. 配置 PA0 模式：CRL 低 4 位控制 PA0；CNF=00 推挽，MODE=10 输出 2MHz */
  GPIOA->CRL = (GPIOA->CRL & ~0xFu) | 0x2u; /* 清掉旧 CNF/MODE，再写入 0b0010 */

  /* 3. 呼吸参数：period 决定亮度阶数，hold 决定每个亮度停留多久 */
  const uint32_t period = 200u; /* PWM 周期拍数；越大亮度分级越细，循环越慢 */
  const uint32_t hold = 15u;    /* 每个占空比重复次数；越大呼吸越慢、越平滑 */

  while (1) { /* 主循环永不退出，持续呼吸 */
    /* 3.1 渐亮：占空比 d 从 0 增到 period */
    for (uint32_t d = 0; d <= period; d++) { /* d 即当前高电平拍数 */
      for (uint32_t i = 0; i < hold; i++) {  /* 同一亮度多打几轮 PWM，让眼睛能跟上 */
        pwm_cycle(d, period);                /* 按当前占空比输出一个 PWM 周期 */
      }
    }
    /* 3.2 渐灭：占空比 d 从 period 减到 1（回到 0 由下一轮渐亮衔接） */
    for (uint32_t d = period; d > 0; d--) { /* 逐级降低高电平时间 */
      for (uint32_t i = 0; i < hold; i++) { /* 同样在每个亮度上停留 hold 轮 */
        pwm_cycle(d, period);               /* 输出更暗一点的 PWM 周期 */
      }
    }
  }
}
