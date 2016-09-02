_ = require 'underscore'
classNames = require 'classnames'
React = require 'react'
ReactDOM = require 'react-dom'
{Utils} = require 'nylas-exports'
DatePicker = require('./date-picker').default
TabGroupRegion = require('./tab-group-region')

idPropType = React.PropTypes.oneOfType([
  React.PropTypes.string
  React.PropTypes.number
])

# The FormItem acts like a React controlled input.
# The `value` will set the "value" of whatever type of form item it is.
# The `onChange` handler will get passed this item's unique index (so
# parents can lookup and change the data appropriately) and the new value.
# Either direct parents, grandparents, etc are responsible for updating
# the `value` prop to update the value again.
class FormItem extends React.Component
  @displayName: "FormItem"

  @inputElementTypes:
    "checkbox": true
    "color": true
    "date": false # We use Nylas DatePicker instead
    "datetime": true
    "datetime-local": true
    "email": true
    "file": true
    "hidden": true
    "month": true
    "number": true
    "password": true
    "radio": true
    "range": true
    "search": true
    "tel": true
    "text": true
    "time": true
    "url": true
    "week": true

  @propTypes:
    # Some sort of unique identifier
    id: idPropType.isRequired

    formItemError: React.PropTypes.shape(
      id: idPropType # The formItemId
      message: React.PropTypes.string
    )

    # Either a type of input or any type that can be passed into
    # `React.createElement(type, ...)`
    type: React.PropTypes.oneOfType([
      React.PropTypes.string
      React.PropTypes.func
    ]).isRequired

    name: React.PropTypes.string
    label: React.PropTypes.node

    # For making all items controlled inputs
    value: React.PropTypes.oneOfType([
      React.PropTypes.string
      React.PropTypes.number
      React.PropTypes.object
      React.PropTypes.bool
    ])

    # For initialization
    defaultValue: React.PropTypes.string

    # selectOptions
    # An array of options.
    selectOptions: React.PropTypes.arrayOf(React.PropTypes.shape(
      label: React.PropTypes.node
      value: React.PropTypes.string
    ))

    # A function that takes two arguments:
    #   - The id of this FormItem
    #   - The new value of the FormItem
    onChange: React.PropTypes.func

    # Common <input> props.
    # Anything that can be passed into a standard React <input> item will
    # be passed along. Here are some common ones. There can be many more
    required: React.PropTypes.bool
    multiple: React.PropTypes.bool
    maxlength: React.PropTypes.number
    placeholder: React.PropTypes.string
    tabIndex: React.PropTypes.number

    referenceTo: React.PropTypes.string

    relationshipName: React.PropTypes.string
    formType: React.PropTypes.oneOf(['new', 'update'])
    editableForNew: React.PropTypes.bool
    editableForUpdate: React.PropTypes.bool

  render: =>
    classes = classNames
      "form-item": true
      "valid": @state.valid

    label = @props.label
    if @props.required
      label = <strong><span className="required">*</span>{@props.label}</strong>

    if @props.type is "hidden"
      @_renderInput()
    else
      <div className={classes}>
        <div className="label-area">
          <label for={@props.id}>{label}</label>
        </div>
        <div className="input-area">
          {@_renderInput()}
          {@_renderError()}
        </div>
      </div>

  # Since the validity state is something we need to pull off of rendered
  # DOM nodes we need to bend the React rules a bit and do a
  # repeated-render until the `state` matches the validity state of the
  # input.
  componentWillMount: =>
    @setState valid: true

  componentDidMount: => @refreshValidityState()

  componentDidUpdate: => @refreshValidityState()

  shouldComponentUpdate: (nextProps, nextState) =>
    not Utils.isEqualReact(nextProps, @props) or
    not Utils.isEqualReact(nextState, @state)

  # We can get an error from the server, or from the HTML Constraint
  # validation APIs. Server errors will be placed on
  # `props.formItemError`. HTML DOM errors will be on the element's
  # `validity` property.
  refreshValidityState: => _.defer =>
    return unless @refs.input
    el = ReactDOM.findDOMNode(@refs.input)

    validityState = {}
    if @props.formItemError
      customError = @props.formItemError.message ? ""
      el.setCustomValidity?(customError)
      validityState = {
        valid: false
        customError: true
        validationMessage: customError
        valueMissing: /required/.test(customError)
      }
    else
      # See https://developer.mozilla.org/en-US/docs/Web/API/ValidityState
      # AND https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement for `validationMessage` property
      el.setCustomValidity?("")
      el.checkValidity?()
      validityState = _.extend {}, el.validity,
        validationMessage: el.validationMessage ? ""

    if not Utils.isEqual(validityState, @_lastValidity)
      @setState validityState

    @_lastValidity = Utils.deepClone(validityState)

  _renderError: =>
    if @state.valid
      <div></div>
    else
      if @state.customError or @_changedOnce
        <div className="form-error">{@state.validationMessage}</div>
      else
        <div></div>

  _isDisabled: =>
    (@props.formType is "new" and @props.editableForNew is false) or
    (@props.formType is "update" and @props.editableForUpdate is false)

  _renderInput: =>
    inputProps = _.extend {}, @props,
      ref: "input"
      onChange: (eventOrValue) =>
        @_changedOnce = true
        @props.onChange(@props.id, ((eventOrValue?.target?.value) ? eventOrValue))
      onBlur: => @refreshValidityState()

    if @_isDisabled() then inputProps.disabled = true

    if FormItem.inputElementTypes[@props.type]
      React.createElement("input", inputProps)
    else if @props.type is "select"
      options = (@props.selectOptions ? []).map (optionData) ->
        <option {...optionData} key={"#{Utils.generateTempId()}-optionData.value"} >{optionData.label}</option>
      options.unshift(<option key={"#{Utils.generateTempId()}-blank-option"}></option>)
      <select {...inputProps}>{options}</select>
    else if @props.type is "textarea"
      React.createElement("textarea", inputProps)
    else if @props.type is "date"
      inputProps.dateFormat = "YYYY-MM-DD"
      React.createElement(DatePicker, inputProps)
    else if _.isFunction(@props.type)
      React.createElement(@props.type, inputProps)
    else
      console.warn "We do not support type #{@props.type} with attributes:", inputProps

class GeneratedFieldset extends React.Component
  @displayName: "GeneratedFieldset"

  @propTypes:
    # Some sort of unique identifier
    id: idPropType.isRequired

    formItems: React.PropTypes.arrayOf(React.PropTypes.shape(
      _.extend(FormItem.propTypes,
        row: React.PropTypes.number
        column: React.PropTypes.number
      )
    ))

    # The key is the formItem id, the value is the error object
    formItemErrors: React.PropTypes.object

    # A function that takes two arguments:
    #   - The id of this GeneratedFieldset
    #   - A new array of updated formItems with the correct value.
    onChange: React.PropTypes.func

    heading: React.PropTypes.node
    useHeading: React.PropTypes.bool
    formType: React.PropTypes.string

  render: =>
    <fieldset>
      {@_renderHeader()}
      <div className="fieldset-form-items">
        {@_renderFormItems()}
      </div>
      {@_renderFooter()}
    </fieldset>

  shouldComponentUpdate: (nextProps, nextState) =>
    not Utils.isEqualReact(nextProps, @props) or
    not Utils.isEqualReact(nextState, @state)

  refreshValidityStates: =>
    for key, ref in @refs
      ref.refreshValidityState() if key.indexOf("form-item") is 0

  _renderHeader: =>
    if @props.useHeading
      <header><legend>{@props.heading}</legend></header>
    else <div></div>

  _renderFormItems: =>
    byRow = _.groupBy(@props.formItems, "row")
    _.map byRow, (itemsInRow=[], rowNum) =>
      byCol = _.groupBy(itemsInRow, "column")
      numCols = Math.max.apply(null, Object.keys(byCol))

      <div className="row"
           data-row-num={rowNum}
           style={zIndex: 1000-rowNum}
           key={rowNum}>
        {_.map byCol, (itemsInCol=[], colNum) =>
          colEls = [<div className="column" data-col-num={colNum} key={colNum}>
            {itemsInCol.map (formItemData) =>
              props = @_propsFromFormItemData(formItemData)
              <FormItem {...props} ref={"form-item-#{formItemData.id}"}/>
            }
          </div>]
          if colNum isnt numCols - 1
            colEls.push(
              <div className="column-spacer" data-col-num={"#{colNum}-spacer"} key={"#{colNum}-spacer"}>
              </div>
            )
          return colEls
        }
      </div>

  # Given the raw data of an individual FormItem, prepare a set of props
  # to pass down into the FormItem.
  _propsFromFormItemData: (formItemData) =>
    props = _.clone(formItemData)
    props.key = props.id
    error = @props.formItemErrors?[props.id]
    if error then props.formItemError = error
    props.onChange = _.bind(@_onChangeItem, @)
    props.formType = @props.formType
    return props

  _onChangeItem: (itemId, newValue) =>
    newFormItems = _.map @props.formItems, (formItem) ->
      if formItem.id is itemId
        newFormItem = _.clone(formItem)
        newFormItem.value = newValue
        return newFormItem
      else return formItem
    @props.onChange(@props.id, newFormItems)

  _renderFooter: =>
    <footer></footer>

class GeneratedForm extends React.Component
  @displayName: "GeneratedForm"

  @propTypes:
    # Some sort of unique identifier
    id: idPropType

    errors: React.PropTypes.shape(
      formError: React.PropTypes.shape(
        message: React.PropTypes.string
        location: React.PropTypes.string # Can be "header" (default) or "footer"
      )
      formItemErrors: GeneratedFieldset.propTypes.formItemErrors
    )

    fieldsets: React.PropTypes.arrayOf(
      React.PropTypes.shape(GeneratedFieldset.propTypes)
    )

    # A function whose argument is a new set of Props
    onChange: React.PropTypes.func.isRequired

    onSubmit: React.PropTypes.func.isRequired

    formType: React.PropTypes.string

  render: =>
    <form className="generated-form" ref="form">
      <TabGroupRegion>
        {@_renderHeaderFormError()}
        <div className="fieldsets">
          {@_renderFieldsets()}
        </div>
        {@_renderHeaderFormError()}
        <div className="form-footer">
          <button className="btn btn-emphasis" onClick={@props.onSubmit}>Submit</button>
        </div>
      </TabGroupRegion>
    </form>

  shouldComponentUpdate: (nextProps, nextState) =>
    not Utils.isEqualReact(nextProps, @props) or
    not Utils.isEqualReact(nextState, @state)

  _onSubmit: =>
    valid = ReactDOM.findDOMNode(@refs.form).reportValidity()
    if valid
      @props.onSubmit()
    else
      @refreshValidityStates()

  refreshValidityStates: =>
    for key, ref in @refs
      ref.refreshValidityStates() if key.indexOf("fieldset") is 0

  _renderHeaderFormError: =>
    if @props.errors?.formError
      <div className="form-error form-header-error">
        {@props.errors.formError.message}
      </div>
    else return <div></div>

  _renderFieldsets: =>
    (@props.fieldsets ? []).map (fieldset) =>
      props = @_propsFromFieldsetData(fieldset)
      <GeneratedFieldset {...props} ref={"fieldset-#{fieldset.id}"} />

  _propsFromFieldsetData: (fieldsetData) =>
    props = _.clone(fieldsetData)
    errors = @props.errors?.formItemErrors
    if errors then props.formItemErrors = errors
    props.key = fieldsetData.id
    props.onChange = _.bind(@_onChangeFieldset, @)
    props.formType = @props.formType
    return props

  _onChangeFieldset: (fieldsetId, newFormItems) =>
    newFieldsets = _.map @props.fieldsets, (fieldset) ->
      if fieldset.id is fieldsetId
        newFieldset = _.clone(fieldset)
        newFieldset.formItems = newFormItems
        return newFieldset
      else return fieldset

    @props.onChange _.extend {}, @props,
      fieldsets: newFieldsets

module.exports =
  FormItem: FormItem
  GeneratedForm: GeneratedForm
  GeneratedFieldset: GeneratedFieldset
