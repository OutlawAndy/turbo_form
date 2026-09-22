// Stimulus generates its manifest from the files in this directory, so a
// controller registered by filename survives `rails generate stimulus`. This
// one is registered as `turbo-form`, which is the identifier the gem's forms
// ask for.
import TurboFormController from "@rolemodel/turbo-form"

export default TurboFormController
