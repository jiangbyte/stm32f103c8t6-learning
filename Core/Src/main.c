/**
 * @file main.c
 * @brief 应用入口（本工程唯一自写业务代码）。
 *
 * 初期：CMSIS 寄存器操作 PC13，练底层。
 * 后续改用 HAL 时对照：
 *   HAL_Init(); 配置时钟; __HAL_RCC_GPIOC_CLK_ENABLE();
 *   HAL_GPIO_Init(GPIOC, ...); HAL_GPIO_TogglePin + HAL_Delay
 * 工程已接入官方 HAL；启动/中断弱符号来自官方 startup，无需自建 it/msp。
 *
 * 时钟：默认复位后 HSI(8MHz)，不配 PLL。
 */
#include "stm32f1xx.h"

/**
 * 粗延时（依赖当前内核时钟，仅用于学习闪灯）。
 */
static void delay_cycles(volatile uint32_t count)
{
  while (count--) {
    __NOP();
  }
}

/**
 * PC13 LED 闪烁（Blue Pill 常见：低电平点亮）。
 */
int main(void)
{
  // 1. 打开 GPIOC 时钟（APB2）
  RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;

  // 2. PC13：推挽输出、2MHz（CNF=00, MODE=10）
  {
    uint32_t crh = GPIOC->CRH;
    crh &= ~(0xFu << 20);
    crh |= (0x2u << 20);
    GPIOC->CRH = crh;
  }

  // 3. 翻转 PC13 + 软件延时
  while (1) {
    GPIOC->ODR ^= (1u << 13);
    delay_cycles(500000u);
  }
}
