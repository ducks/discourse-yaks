# frozen_string_literal: true

require "json"

namespace :yaks do
  desc "Audit Yak balances against the transaction ledger; pass [repair] to correct drift"
  task :reconcile, [:mode] => :environment do |_task, args|
    repair = args[:mode] == "repair"
    result = YakLedgerReconciler.run(repair: repair)

    puts JSON.pretty_generate(result)
    puts repair ? "Yak reconciliation repair complete." : "Dry run only; no records changed."
  end
end
