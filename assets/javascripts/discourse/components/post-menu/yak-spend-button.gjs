import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import SpendYaksModal from "../modal/spend-yaks";

export default class YakSpendButton extends Component {
  @service modal;

  @action
  openModal() {
    this.modal.show(SpendYaksModal, {
      model: {
        post: this.args.post,
      },
    });
  }

  <template>
    <DButton
      @action={{this.openModal}}
      @icon="gift"
      @label="yaks.post_action.spend"
      @title="yaks.post_action.spend_yaks"
      class="yak-spend post-action-menu__yak-spend"
    />
  </template>
}
