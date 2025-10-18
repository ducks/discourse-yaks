import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DModal from "discourse/components/d-modal";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class NewYakPackageModal extends Component {
  @service router;
  @tracked saving = false;

  get formData() {
    return {
      name: "",
      description: "",
      price_usd: 5,
      yaks: 100,
      bonus_yaks: 0,
      enabled: true,
    };
  }

  @action
  async save(data) {
    this.saving = true;

    try {
      await ajax("/admin/plugins/yaks/packages", {
        type: "POST",
        data: {
          name: data.name,
          description: data.description,
          price_usd: parseFloat(data.price_usd),
          yaks: parseInt(data.yaks, 10),
          bonus_yaks: parseInt(data.bonus_yaks, 10),
          enabled: data.enabled,
        },
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
      @title="Create New Package"
      @closeModal={{@closeModal}}
      class="new-yak-package-modal"
    >
      <:body>
        <Form
          @data={{this.formData}}
          @onSubmit={{this.save}}
          as |form|
        >
          <form.Field
            @name="name"
            @title="Package Name"
            @validation="required"
            @description="E.g., 'Starter Pack', 'Value Pack', etc."
            as |field|
          >
            <field.Input />
          </form.Field>

          <form.Field
            @name="description"
            @title="Description"
            @description="Optional description shown to users"
            as |field|
          >
            <field.Textarea />
          </form.Field>

          <form.Field
            @name="price_usd"
            @title="Price (USD)"
            @validation="required|number"
            @description="How much this package costs in dollars"
            as |field|
          >
            <field.Input @type="number" min="0.01" step="0.01" />
          </form.Field>

          <form.Field
            @name="yaks"
            @title="Base Yaks"
            @validation="required|number"
            @description="Number of Yaks included in this package"
            as |field|
          >
            <field.Input @type="number" min="1" />
          </form.Field>

          <form.Field
            @name="bonus_yaks"
            @title="Bonus Yaks"
            @validation="required|number"
            @description="Extra bonus Yaks (use 0 for no bonus)"
            as |field|
          >
            <field.Input @type="number" min="0" />
          </form.Field>

          <form.Field
            @name="enabled"
            @title="Enabled"
            @description="Make this package available for purchase immediately"
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
