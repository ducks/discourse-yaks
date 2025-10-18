import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class EditYakFeatureModal extends Component {
  @service router;
  @tracked saving = false;

  get feature() {
    return this.args.model.feature;
  }

  get formData() {
    return {
      feature_name: this.feature.feature_name,
      description: this.feature.description,
      cost: this.feature.cost,
      enabled: this.feature.enabled,
      duration_hours: this.feature.settings?.duration_hours || null,
      duration_days: this.feature.settings?.duration_days || null,
    };
  }

  @action
  async save(data) {
    this.saving = true;

    try {
      const settings = {};
      if (data.duration_hours) {
        settings.duration_hours = parseInt(data.duration_hours, 10);
      }
      if (data.duration_days) {
        settings.duration_days = parseInt(data.duration_days, 10);
      }

      const payload = {
        feature_name: data.feature_name,
        description: data.description,
        cost: parseInt(data.cost, 10),
        enabled: data.enabled,
        settings,
      };

      await ajax(`/admin/plugins/yaks/features/${this.feature.id}`, {
        type: "PUT",
        data: payload,
      });

      this.args.closeModal();
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <DModal
      @title="Edit Feature: {{this.feature.feature_name}}"
      @closeModal={{@closeModal}}
      class="edit-yak-feature-modal"
    >
      <:body>
        <Form
          @data={{this.formData}}
          @onSubmit={{this.save}}
          as |form|
        >
          <form.Field
            @name="feature_name"
            @title="Feature Name"
            @validation="required"
            as |field|
          >
            <field.Input />
          </form.Field>

          <form.Field
            @name="description"
            @title="Description"
            as |field|
          >
            <field.Textarea />
          </form.Field>

          <form.Field
            @name="cost"
            @title="Cost (Yaks)"
            @validation="required|number"
            as |field|
          >
            <field.Input @type="number" />
          </form.Field>

          <form.Field
            @name="duration_hours"
            @title="Duration (Hours)"
            @description="Leave empty for permanent features"
            as |field|
          >
            <field.Input @type="number" />
          </form.Field>

          <form.Field
            @name="duration_days"
            @title="Duration (Days)"
            @description="Alternatively, specify days instead of hours"
            as |field|
          >
            <field.Input @type="number" />
          </form.Field>

          <form.Field
            @name="enabled"
            @title="Enabled"
            @description="Make this feature available for purchase"
            as |field|
          >
            <field.Checkbox />
          </form.Field>

          <form.Submit @disabled={{this.saving}} />
        </Form>
      </:body>
    </DModal>
  </template>
}
