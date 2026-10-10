import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { WidgetDataBuilder, WidgetSnapshot } from '../model/WidgetDataBuilder';
import { WidgetPusher } from '../model/WidgetPusher';
import { WidgetSnapshotStore } from '../model/WidgetSnapshotStore';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const parameters: Record<string, Object> = want.parameters as Record<string, Object>;
    if (parameters === undefined || parameters === null) {
      return formBindingData.createFormBindingData({});
    }
    const formName: string = (parameters[formInfo.FormParam.NAME_KEY] as string) ?? 'daily_card';
    const formId: string = (parameters[formInfo.FormParam.IDENTITY_KEY] as string) ?? '';
    console.info(`EntryFormAbility.onAddForm formId=${formId} name=${formName}`);
    if (formId.length > 0) {
      WidgetSnapshotStore.registerForm(this.context, formId, formName)
        .then(() => {
          this.updateFormWithFreshData(formId, formName);
        })
        .catch((e: BusinessError) => {
          console.error(`registerForm error: ${e.code} ${e.message}`);
        });
    }
    return this.initialBindingData(formName);
  }

  onUpdateForm(formId: string): void {
    console.info(`EntryFormAbility.onUpdateForm formId=${formId}`);
    WidgetSnapshotStore.findFormName(this.context, formId).then((formName: string) => {
      const name: string = formName.length > 0 ? formName : 'daily_card';
      this.updateFormWithFreshData(formId, name);
    }).catch((e: BusinessError) => {
      console.error(`findFormName error: ${e.code} ${e.message}`);
      this.updateFormWithFreshData(formId, 'daily_card');
    });
  }

  onRemoveForm(formId: string): void {
    console.info(`EntryFormAbility.onRemoveForm formId=${formId}`);
    WidgetSnapshotStore.unregisterForm(this.context, formId)
      .catch((e: BusinessError) => {
        console.error(`unregisterForm error: ${e.code} ${e.message}`);
      });
  }

  onFormEvent(formId: string, message: string): void {
    console.info(`EntryFormAbility.onFormEvent formId=${formId} message=${message}`);
  }

  private updateFormWithFreshData(formId: string, formName: string): void {
    WidgetPusher.buildFromStore(this.context, new Date()).then((snaps: WidgetSnapshot[]) => {
      let json: string = WidgetDataBuilder.defaultJson(formName);
      if (snaps.length > 0) {
        const matched: string = WidgetPusher.jsonFor(snaps, formName);
        if (matched.length > 0) {
          json = matched;
        }
        const pairs: Array<[string, string]> = [];
        for (let i = 0; i < snaps.length; i++) {
          pairs.push([snaps[i].formName, snaps[i].json]);
        }
        WidgetSnapshotStore.saveSnapshots(this.context, pairs);
      }
      formProvider.updateForm(formId, formBindingData.createFormBindingData({ cardData: json }))
        .then(() => {
          console.info(`updateForm ok formId=${formId} name=${formName}`);
        })
        .catch((e: BusinessError) => {
          console.error(`updateForm error: ${e.code} ${e.message}`);
        });
    }).catch((e: BusinessError) => {
      console.error(`buildFromStore error: ${e.code} ${e.message}`);
      const json: string = WidgetDataBuilder.defaultJson(formName);
      formProvider.updateForm(formId, formBindingData.createFormBindingData({ cardData: json }))
        .catch((err: BusinessError) => {
          console.error(`updateForm fallback error: ${err.code} ${err.message}`);
        });
    });
  }

  private initialBindingData(formName: string): formBindingData.FormBindingData {
    const data: string = WidgetDataBuilder.defaultJson(formName);
    return formBindingData.createFormBindingData({ cardData: data });
  }
}