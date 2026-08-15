/**
 * 绩点计算 —— 移植自 Android 参考实现 GradeMath.java
 */
export class GradeMath {
  static weightedAverage(credits: Array<number>, values: Array<number>): number {
    if (credits === null || values === null || credits.length !== values.length) {
      throw new Error('credits and values must have equal lengths');
    }
    let weighted = 0;
    let includedCredits = 0;
    for (let i = 0; i < credits.length; i++) {
      if (credits[i] > 0 && Number.isFinite(values[i])) {
        weighted += credits[i] * values[i];
        includedCredits += credits[i];
      }
    }
    return includedCredits === 0 ? Number.NaN : weighted / includedCredits;
  }
}
