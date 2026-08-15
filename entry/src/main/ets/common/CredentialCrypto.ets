/**
 * 凭据加密 —— 使用 @kit.CryptoArchitectureKit 的 AES-GCM 对称加密
 * 密码以密文形式保存在本地 Preferences，解密仅在同步时临时使用。
 * 说明：该加密仅用于保护用户本人凭据的静态存储，密钥由应用内固定种子派生。
 */
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

export class CredentialCrypto {
  private static readonly IV_LENGTH = 12;
  private static readonly TAG_LENGTH = 16;
  private static readonly KEY_ALG = 'AES128';
  private static readonly CIPHER_ALG = 'AES128|GCM|PKCS7';

  /** 加密明文密码，返回 "nonce(iv) + authTag + ciphertext" 的 Base64 串 */
  static async encrypt(plain: string): Promise<string> {
    const key = await CredentialCrypto.getOrCreateKey();
    const cipher = cryptoFramework.createCipher(CredentialCrypto.CIPHER_ALG);
    const random = cryptoFramework.createRandom();
    const ivBlob = random.generateRandomSync(CredentialCrypto.IV_LENGTH);
    const gcmParams: cryptoFramework.GcmParamsSpec = {
      iv: { data: ivBlob.data },
      aad: { data: new Uint8Array(0) },
      authTag: { data: new Uint8Array(CredentialCrypto.TAG_LENGTH) },
      algName: 'GcmParamsSpec'
    };
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, gcmParams);
    const plainBytes = new util.TextEncoder().encodeInto(plain);
    const encryptData = await cipher.update({ data: plainBytes });
    const tagBlob = await cipher.doFinal(null);
    const tag = tagBlob === null ? new Uint8Array(CredentialCrypto.TAG_LENGTH) : tagBlob.data;

    const cipherBytes = encryptData === null ? new Uint8Array(0) : encryptData.data;
    const result = new Uint8Array(ivBlob.data.length + tag.length + cipherBytes.length);
    result.set(ivBlob.data, 0);
    result.set(tag, ivBlob.data.length);
    result.set(cipherBytes, ivBlob.data.length + tag.length);
    const helper = new util.Base64Helper();
    return helper.encodeToStringSync(result);
  }

  /** 解密密码，失败返回空字符串 */
  static async decrypt(encrypted: string): Promise<string> {
    try {
      const key = await CredentialCrypto.getOrCreateKey();
      const helper = new util.Base64Helper();
      const all = helper.decodeSync(encrypted);
      if (all.length < CredentialCrypto.IV_LENGTH + CredentialCrypto.TAG_LENGTH) {
        return '';
      }
      const iv = all.slice(0, CredentialCrypto.IV_LENGTH);
      const tag = all.slice(CredentialCrypto.IV_LENGTH, CredentialCrypto.IV_LENGTH + CredentialCrypto.TAG_LENGTH);
      const data = all.slice(CredentialCrypto.IV_LENGTH + CredentialCrypto.TAG_LENGTH);
      const decoder = cryptoFramework.createCipher(CredentialCrypto.CIPHER_ALG);
      const gcmParams: cryptoFramework.GcmParamsSpec = {
        iv: { data: iv },
        aad: { data: new Uint8Array(0) },
        authTag: { data: tag },
        algName: 'GcmParamsSpec'
      };
      await decoder.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, gcmParams);
      const decryptData = await decoder.update({ data: data });
      await decoder.doFinal(null);
      const plainBytes = decryptData === null ? new Uint8Array(0) : decryptData.data;
      return new util.TextDecoder().decodeToString(plainBytes);
    } catch (e) {
      return '';
    }
  }

  private static async getOrCreateKey(): Promise<cryptoFramework.SymKey> {
    const generator = cryptoFramework.createSymKeyGenerator(CredentialCrypto.KEY_ALG);
    const seed = 'aoxiang_assistant_nwpu_2026';
    const seedBytes = new util.TextEncoder().encodeInto(seed);
    const keyBytes = new Uint8Array(16);
    for (let i = 0; i < 16; i++) {
      keyBytes[i] = seedBytes[i % seedBytes.length] ^ 0x5A;
    }
    const keyBlob: cryptoFramework.DataBlob = { data: keyBytes };
    return generator.convertKey(keyBlob);
  }
}
