/**
 * 更新差异检测 —— 移植自 Android 参考实现 UpdateDiff.java
 * 用于课表/成绩同步后的变更通知。
 */
export class UpdateDiff {
  static readonly KEY_SEPARATOR = '\u0001';

  static changedNames(before: Array<UpdateDiffItem>, after: Array<UpdateDiffItem>): Array<string> {
    const oldItems: Map<string, UpdateDiffItem> = new Map();
    const newItems: Map<string, UpdateDiffItem> = new Map();
    for (const item of before) {
      oldItems.set(item.key, item);
    }
    for (const item of after) {
      newItems.set(item.key, item);
    }
    const keys: Set<string> = new Set();
    for (const key of oldItems.keys()) {
      keys.add(key);
    }
    for (const key of newItems.keys()) {
      keys.add(key);
    }
    const names: Set<string> = new Set();
    for (const key of keys) {
      const oldItem = oldItems.get(key);
      const newItem = newItems.get(key);
      if (oldItem === undefined || newItem === undefined) {
        const name = newItem === undefined ? (oldItem === undefined ? '' : oldItem.name) : newItem.name;
        if (name !== '') {
          names.add(name);
        }
        continue;
      }
      if (oldItem.signature !== newItem.signature) {
        if (newItem.name !== '') {
          names.add(newItem.name);
        }
      }
    }
    const result = Array.from(names);
    result.sort();
    return result;
  }

  static notificationText(courseNames: Array<string>, grades: boolean): string {
    if (courseNames === null || courseNames.length === 0) {
      return grades ? '成绩有更新' : '课表有更新';
    }
    const suffix = grades ? '成绩有更新' : '排课有更新';
    if (courseNames.length <= 3) {
      return `${courseNames.join('、')}${suffix}`;
    }
    return `${courseNames.slice(0, 3).join('、')}等 ${courseNames.length} 门课程${suffix}`;
  }

  static clean(value: string): string {
    if (value === null || value === undefined) {
      return '';
    }
    return value.trim();
  }
}

export class UpdateDiffItem {
  key: string;
  name: string;
  signature: string;

  constructor(key: string, name: string, signature: string) {
    this.key = UpdateDiff.clean(key);
    this.name = UpdateDiff.clean(name);
    this.signature = signature === null ? '' : signature;
  }
}
