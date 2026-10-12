import { common, Want } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { request } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class UpdateSource {
  static readonly ATOM_GIT: string = 'atomgit';
  static readonly GITHUB: string = 'github';
}

export class ReleaseAsset {
  name: string = '';
  url: string = '';
}

export class ReleaseInfo {
  tagName: string = '';
  name: string = '';
  body: string = '';
  publishedAt: string = '';
  isPrerelease: boolean = false;
  assets: ReleaseAsset[] = [];
}

function textOf(value: Object | undefined): string {
  if (value === undefined || value === null) {
    return '';
  }
  return `${value}`;
}

export class Updater {
  static readonly ATOM_API: string = 'https://api.atomgit.com/api/v5/repos/valuelesser/AoxiangAssistant/releases';
  static readonly GITHUB_API: string = 'https://api.github.com/repos/valuelesser/aoxiang-assistant/releases';

  static sourceLabel(source: string): string {
    return source === UpdateSource.GITHUB ? 'GitHub' : 'atomgit';
  }

  static parseVersion(tag: string): number[] {
    const cleaned: string = tag.replace(/^v/i, '').trim();
    const parts: string[] = cleaned.split('.');
    const out: number[] = [];
    for (let i = 0; i < parts.length; i++) {
      const n: number = parseInt(parts[i], 10);
      out.push(isFinite(n) ? n : 0);
    }
    return out;
  }

  static compareVersion(a: number[], b: number[]): number {
    const len: number = Math.max(a.length, b.length);
    for (let i = 0; i < len; i++) {
      const av: number = i < a.length ? a[i] : 0;
      const bv: number = i < b.length ? b[i] : 0;
      if (av > bv) {
        return 1;
      }
      if (av < bv) {
        return -1;
      }
    }
    return 0;
  }

  static hapAsset(release: ReleaseInfo): ReleaseAsset | undefined {
    for (let i = 0; i < release.assets.length; i++) {
      const name: string = release.assets[i].name;
      if (name.startsWith('aoxiang') && name.endsWith('.hap')) {
        return release.assets[i];
      }
    }
    return undefined;
  }

  static async checkLatest(source: string): Promise<ReleaseInfo | undefined> {
    let req: http.HttpRequest | undefined = undefined;
    try {
      req = http.createHttp();
      const url: string = source === UpdateSource.GITHUB ? Updater.GITHUB_API : Updater.ATOM_API;
      const resp: http.HttpResponse = await req.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 15000,
        readTimeout: 15000,
        header: { 'Accept': 'application/json' },
      });
      if (resp.responseCode !== 200) {
        return undefined;
      }
      const result: string = typeof resp.result === 'string' ? resp.result : '';
      if (result.length === 0) {
        return undefined;
      }
      const arr: Object[] = JSON.parse(result) as Object[];
      let best: ReleaseInfo | undefined = undefined;
      let bestVer: number[] = [];
      for (let i = 0; i < arr.length; i++) {
        const obj: Record<string, Object> = arr[i] as Record<string, Object>;
        if (obj === undefined || obj === null) {
          continue;
        }
        if ((obj['prerelease'] ?? false) === true) {
          continue;
        }
        const rel: ReleaseInfo = new ReleaseInfo();
        rel.tagName = textOf(obj['tag_name']);
        rel.name = textOf(obj['name']);
        rel.body = textOf(obj['body']);
        rel.publishedAt = textOf(obj['published_at']);
        if (rel.publishedAt.length === 0) {
          rel.publishedAt = textOf(obj['created_at']);
        }
        const rawAssets: Object | undefined = obj['assets'];
        if (rawAssets !== undefined && rawAssets !== null) {
          const arrA: Object[] = rawAssets as Object[];
          for (let j = 0; j < arrA.length; j++) {
            const a: Record<string, Object> = arrA[j] as Record<string, Object>;
            if (a === undefined || a === null) {
              continue;
            }
            const asset: ReleaseAsset = new ReleaseAsset();
            asset.name = textOf(a['name']);
            const urlA: string = textOf(a['browser_download_url']);
            asset.url = urlA.length > 0 ? urlA : textOf(a['download_url']);
            if (asset.name.length > 0) {
              rel.assets.push(asset);
            }
          }
        }
        if (Updater.hapAsset(rel) === undefined) {
          continue;
        }
        const ver: number[] = Updater.parseVersion(rel.tagName);
        if (best === undefined || Updater.compareVersion(ver, bestVer) > 0) {
          best = rel;
          bestVer = ver;
        }
      }
      return best;
    } catch (e) {
      console.error(`Updater.checkLatest error: ${e}`);
      return undefined;
    } finally {
      if (req !== undefined) {
        req.destroy();
      }
    }
  }

  static async downloadHap(context: common.Context, url: string, fileName: string,
                           onProgress: (received: number, total: number) => void): Promise<string> {
    const dir: string = `${context.filesDir}/updates`;
    try {
      fs.mkdirSync(dir, true);
    } catch (e) {
      console.error(`Updater.mkdir error: ${e}`);
    }
    const filePath: string = `${dir}/${fileName}`;
    const task: request.DownloadTask = await request.downloadFile(context, {
      url: url,
      filePath: filePath,
    });
    task.on('progress', (receivedSize: number, totalSize: number) => {
      onProgress(receivedSize, totalSize);
    });
    return new Promise<string>((resolve, reject) => {
      task.on('complete', () => {
        task.off('complete');
        resolve(filePath);
      });
      task.on('fail', (err: number) => {
        task.off('fail');
        reject(err);
      });
    });
  }

  static uriFor(path: string): string {
    return fileUri.getUriFromPath(path);
  }

  static async openHap(context: common.UIAbilityContext, path: string): Promise<boolean> {
    const uri: string = Updater.uriFor(path);
    try {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: uri,
        type: 'application/hap',
      };
      await context.startAbility(want);
      return true;
    } catch (e) {
      console.error(`Updater.openHap(type) error: ${e}`);
    }
    try {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: uri,
      };
      await context.startAbility(want);
      return true;
    } catch (e) {
      console.error(`Updater.openHap(plain) error: ${e}`);
    }
    return false;
  }
}
