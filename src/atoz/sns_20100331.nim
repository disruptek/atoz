
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Notification Service
## version: 2010-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Simple Notification Service</fullname> <p>Amazon Simple Notification Service (Amazon SNS) is a web service that enables you to build distributed web-enabled applications. Applications can use Amazon SNS to easily push real-time notification messages to interested subscribers over multiple delivery protocols. For more information about this product see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. For detailed information about Amazon SNS features and their associated API calls, see the <a href="https://docs.aws.amazon.com/sns/latest/dg/">Amazon SNS Developer Guide</a>. </p> <p>We also provide SDKs that enable you to access Amazon SNS from your preferred programming language. The SDKs contain functionality that automatically takes care of tasks such as: cryptographically signing your service requests, retrying requests, and handling error responses. For a list of available SDKs, go to <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sns/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "sns.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sns.ap-southeast-1.amazonaws.com",
                           "us-west-2": "sns.us-west-2.amazonaws.com",
                           "eu-west-2": "sns.eu-west-2.amazonaws.com", "ap-northeast-3": "sns.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "sns.eu-central-1.amazonaws.com",
                           "us-east-2": "sns.us-east-2.amazonaws.com",
                           "us-east-1": "sns.us-east-1.amazonaws.com", "cn-northwest-1": "sns.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "sns.ap-south-1.amazonaws.com",
                           "eu-north-1": "sns.eu-north-1.amazonaws.com", "ap-northeast-2": "sns.ap-northeast-2.amazonaws.com",
                           "us-west-1": "sns.us-west-1.amazonaws.com",
                           "us-gov-east-1": "sns.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "sns.eu-west-3.amazonaws.com",
                           "cn-north-1": "sns.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "sns.sa-east-1.amazonaws.com",
                           "eu-west-1": "sns.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "sns.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sns.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "sns.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "sns.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "sns.ap-southeast-1.amazonaws.com",
      "us-west-2": "sns.us-west-2.amazonaws.com",
      "eu-west-2": "sns.eu-west-2.amazonaws.com",
      "ap-northeast-3": "sns.ap-northeast-3.amazonaws.com",
      "eu-central-1": "sns.eu-central-1.amazonaws.com",
      "us-east-2": "sns.us-east-2.amazonaws.com",
      "us-east-1": "sns.us-east-1.amazonaws.com",
      "cn-northwest-1": "sns.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "sns.ap-south-1.amazonaws.com",
      "eu-north-1": "sns.eu-north-1.amazonaws.com",
      "ap-northeast-2": "sns.ap-northeast-2.amazonaws.com",
      "us-west-1": "sns.us-west-1.amazonaws.com",
      "us-gov-east-1": "sns.us-gov-east-1.amazonaws.com",
      "eu-west-3": "sns.eu-west-3.amazonaws.com",
      "cn-north-1": "sns.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "sns.sa-east-1.amazonaws.com",
      "eu-west-1": "sns.eu-west-1.amazonaws.com",
      "us-gov-west-1": "sns.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "sns.ap-southeast-2.amazonaws.com",
      "ca-central-1": "sns.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sns"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_773207 = ref object of OpenApiRestCall_772597
proc url_PostAddPermission_773209(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddPermission_773208(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773210 = query.getOrDefault("Action")
  valid_773210 = validateParameter(valid_773210, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_773210 != nil:
    section.add "Action", valid_773210
  var valid_773211 = query.getOrDefault("Version")
  valid_773211 = validateParameter(valid_773211, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773211 != nil:
    section.add "Version", valid_773211
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773212 = header.getOrDefault("X-Amz-Date")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Date", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Security-Token")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Security-Token", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Content-Sha256", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Algorithm")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Algorithm", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Signature")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Signature", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-SignedHeaders", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Credential")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Credential", valid_773218
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_773219 = formData.getOrDefault("TopicArn")
  valid_773219 = validateParameter(valid_773219, JString, required = true,
                                 default = nil)
  if valid_773219 != nil:
    section.add "TopicArn", valid_773219
  var valid_773220 = formData.getOrDefault("AWSAccountId")
  valid_773220 = validateParameter(valid_773220, JArray, required = true, default = nil)
  if valid_773220 != nil:
    section.add "AWSAccountId", valid_773220
  var valid_773221 = formData.getOrDefault("Label")
  valid_773221 = validateParameter(valid_773221, JString, required = true,
                                 default = nil)
  if valid_773221 != nil:
    section.add "Label", valid_773221
  var valid_773222 = formData.getOrDefault("ActionName")
  valid_773222 = validateParameter(valid_773222, JArray, required = true, default = nil)
  if valid_773222 != nil:
    section.add "ActionName", valid_773222
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773223: Call_PostAddPermission_773207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_773223.validator(path, query, header, formData, body)
  let scheme = call_773223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773223.url(scheme.get, call_773223.host, call_773223.base,
                         call_773223.route, valid.getOrDefault("path"))
  result = hook(call_773223, url, valid)

proc call*(call_773224: Call_PostAddPermission_773207; TopicArn: string;
          AWSAccountId: JsonNode; Label: string; ActionName: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## postAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   Action: string (required)
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Version: string (required)
  var query_773225 = newJObject()
  var formData_773226 = newJObject()
  add(formData_773226, "TopicArn", newJString(TopicArn))
  if AWSAccountId != nil:
    formData_773226.add "AWSAccountId", AWSAccountId
  add(formData_773226, "Label", newJString(Label))
  add(query_773225, "Action", newJString(Action))
  if ActionName != nil:
    formData_773226.add "ActionName", ActionName
  add(query_773225, "Version", newJString(Version))
  result = call_773224.call(nil, query_773225, nil, formData_773226, nil)

var postAddPermission* = Call_PostAddPermission_773207(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_773208,
    base: "/", url: url_PostAddPermission_773209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_772933 = ref object of OpenApiRestCall_772597
proc url_GetAddPermission_772935(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddPermission_772934(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ActionName` field"
  var valid_773047 = query.getOrDefault("ActionName")
  valid_773047 = validateParameter(valid_773047, JArray, required = true, default = nil)
  if valid_773047 != nil:
    section.add "ActionName", valid_773047
  var valid_773061 = query.getOrDefault("Action")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_773061 != nil:
    section.add "Action", valid_773061
  var valid_773062 = query.getOrDefault("TopicArn")
  valid_773062 = validateParameter(valid_773062, JString, required = true,
                                 default = nil)
  if valid_773062 != nil:
    section.add "TopicArn", valid_773062
  var valid_773063 = query.getOrDefault("Version")
  valid_773063 = validateParameter(valid_773063, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773063 != nil:
    section.add "Version", valid_773063
  var valid_773064 = query.getOrDefault("Label")
  valid_773064 = validateParameter(valid_773064, JString, required = true,
                                 default = nil)
  if valid_773064 != nil:
    section.add "Label", valid_773064
  var valid_773065 = query.getOrDefault("AWSAccountId")
  valid_773065 = validateParameter(valid_773065, JArray, required = true, default = nil)
  if valid_773065 != nil:
    section.add "AWSAccountId", valid_773065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773066 = header.getOrDefault("X-Amz-Date")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Date", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Security-Token")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Security-Token", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Content-Sha256", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-Algorithm")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-Algorithm", valid_773069
  var valid_773070 = header.getOrDefault("X-Amz-Signature")
  valid_773070 = validateParameter(valid_773070, JString, required = false,
                                 default = nil)
  if valid_773070 != nil:
    section.add "X-Amz-Signature", valid_773070
  var valid_773071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773071 = validateParameter(valid_773071, JString, required = false,
                                 default = nil)
  if valid_773071 != nil:
    section.add "X-Amz-SignedHeaders", valid_773071
  var valid_773072 = header.getOrDefault("X-Amz-Credential")
  valid_773072 = validateParameter(valid_773072, JString, required = false,
                                 default = nil)
  if valid_773072 != nil:
    section.add "X-Amz-Credential", valid_773072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773095: Call_GetAddPermission_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_773095.validator(path, query, header, formData, body)
  let scheme = call_773095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773095.url(scheme.get, call_773095.host, call_773095.base,
                         call_773095.route, valid.getOrDefault("path"))
  result = hook(call_773095, url, valid)

proc call*(call_773166: Call_GetAddPermission_772933; ActionName: JsonNode;
          TopicArn: string; Label: string; AWSAccountId: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## getAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  var query_773167 = newJObject()
  if ActionName != nil:
    query_773167.add "ActionName", ActionName
  add(query_773167, "Action", newJString(Action))
  add(query_773167, "TopicArn", newJString(TopicArn))
  add(query_773167, "Version", newJString(Version))
  add(query_773167, "Label", newJString(Label))
  if AWSAccountId != nil:
    query_773167.add "AWSAccountId", AWSAccountId
  result = call_773166.call(nil, query_773167, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_772933(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_772934,
    base: "/", url: url_GetAddPermission_772935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_773243 = ref object of OpenApiRestCall_772597
proc url_PostCheckIfPhoneNumberIsOptedOut_773245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCheckIfPhoneNumberIsOptedOut_773244(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773246 = query.getOrDefault("Action")
  valid_773246 = validateParameter(valid_773246, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_773246 != nil:
    section.add "Action", valid_773246
  var valid_773247 = query.getOrDefault("Version")
  valid_773247 = validateParameter(valid_773247, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773247 != nil:
    section.add "Version", valid_773247
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773248 = header.getOrDefault("X-Amz-Date")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Date", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Security-Token")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Security-Token", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Content-Sha256", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Algorithm")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Algorithm", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Signature")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Signature", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-SignedHeaders", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Credential")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Credential", valid_773254
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_773255 = formData.getOrDefault("phoneNumber")
  valid_773255 = validateParameter(valid_773255, JString, required = true,
                                 default = nil)
  if valid_773255 != nil:
    section.add "phoneNumber", valid_773255
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773256: Call_PostCheckIfPhoneNumberIsOptedOut_773243;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_773256.validator(path, query, header, formData, body)
  let scheme = call_773256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773256.url(scheme.get, call_773256.host, call_773256.base,
                         call_773256.route, valid.getOrDefault("path"))
  result = hook(call_773256, url, valid)

proc call*(call_773257: Call_PostCheckIfPhoneNumberIsOptedOut_773243;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Version: string (required)
  var query_773258 = newJObject()
  var formData_773259 = newJObject()
  add(query_773258, "Action", newJString(Action))
  add(formData_773259, "phoneNumber", newJString(phoneNumber))
  add(query_773258, "Version", newJString(Version))
  result = call_773257.call(nil, query_773258, nil, formData_773259, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_773243(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_773244, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_773245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_773227 = ref object of OpenApiRestCall_772597
proc url_GetCheckIfPhoneNumberIsOptedOut_773229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCheckIfPhoneNumberIsOptedOut_773228(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `phoneNumber` field"
  var valid_773230 = query.getOrDefault("phoneNumber")
  valid_773230 = validateParameter(valid_773230, JString, required = true,
                                 default = nil)
  if valid_773230 != nil:
    section.add "phoneNumber", valid_773230
  var valid_773231 = query.getOrDefault("Action")
  valid_773231 = validateParameter(valid_773231, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_773231 != nil:
    section.add "Action", valid_773231
  var valid_773232 = query.getOrDefault("Version")
  valid_773232 = validateParameter(valid_773232, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773232 != nil:
    section.add "Version", valid_773232
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773233 = header.getOrDefault("X-Amz-Date")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Date", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Security-Token")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Security-Token", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Content-Sha256", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Algorithm")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Algorithm", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Signature")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Signature", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-SignedHeaders", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Credential")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Credential", valid_773239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773240: Call_GetCheckIfPhoneNumberIsOptedOut_773227;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_773240.validator(path, query, header, formData, body)
  let scheme = call_773240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773240.url(scheme.get, call_773240.host, call_773240.base,
                         call_773240.route, valid.getOrDefault("path"))
  result = hook(call_773240, url, valid)

proc call*(call_773241: Call_GetCheckIfPhoneNumberIsOptedOut_773227;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773242 = newJObject()
  add(query_773242, "phoneNumber", newJString(phoneNumber))
  add(query_773242, "Action", newJString(Action))
  add(query_773242, "Version", newJString(Version))
  result = call_773241.call(nil, query_773242, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_773227(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_773228, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_773229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_773278 = ref object of OpenApiRestCall_772597
proc url_PostConfirmSubscription_773280(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostConfirmSubscription_773279(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773281 = query.getOrDefault("Action")
  valid_773281 = validateParameter(valid_773281, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_773281 != nil:
    section.add "Action", valid_773281
  var valid_773282 = query.getOrDefault("Version")
  valid_773282 = validateParameter(valid_773282, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773282 != nil:
    section.add "Version", valid_773282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773283 = header.getOrDefault("X-Amz-Date")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Date", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Security-Token")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Security-Token", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Content-Sha256", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Algorithm")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Algorithm", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Signature")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Signature", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-SignedHeaders", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-Credential")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Credential", valid_773289
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_773290 = formData.getOrDefault("TopicArn")
  valid_773290 = validateParameter(valid_773290, JString, required = true,
                                 default = nil)
  if valid_773290 != nil:
    section.add "TopicArn", valid_773290
  var valid_773291 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_773291
  var valid_773292 = formData.getOrDefault("Token")
  valid_773292 = validateParameter(valid_773292, JString, required = true,
                                 default = nil)
  if valid_773292 != nil:
    section.add "Token", valid_773292
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773293: Call_PostConfirmSubscription_773278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_773293.validator(path, query, header, formData, body)
  let scheme = call_773293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773293.url(scheme.get, call_773293.host, call_773293.base,
                         call_773293.route, valid.getOrDefault("path"))
  result = hook(call_773293, url, valid)

proc call*(call_773294: Call_PostConfirmSubscription_773278; TopicArn: string;
          Token: string; AuthenticateOnUnsubscribe: string = "";
          Action: string = "ConfirmSubscription"; Version: string = "2010-03-31"): Recallable =
  ## postConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  var query_773295 = newJObject()
  var formData_773296 = newJObject()
  add(formData_773296, "TopicArn", newJString(TopicArn))
  add(formData_773296, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_773295, "Action", newJString(Action))
  add(query_773295, "Version", newJString(Version))
  add(formData_773296, "Token", newJString(Token))
  result = call_773294.call(nil, query_773295, nil, formData_773296, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_773278(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_773279, base: "/",
    url: url_PostConfirmSubscription_773280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_773260 = ref object of OpenApiRestCall_772597
proc url_GetConfirmSubscription_773262(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConfirmSubscription_773261(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_773263 = query.getOrDefault("Token")
  valid_773263 = validateParameter(valid_773263, JString, required = true,
                                 default = nil)
  if valid_773263 != nil:
    section.add "Token", valid_773263
  var valid_773264 = query.getOrDefault("Action")
  valid_773264 = validateParameter(valid_773264, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_773264 != nil:
    section.add "Action", valid_773264
  var valid_773265 = query.getOrDefault("TopicArn")
  valid_773265 = validateParameter(valid_773265, JString, required = true,
                                 default = nil)
  if valid_773265 != nil:
    section.add "TopicArn", valid_773265
  var valid_773266 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_773266
  var valid_773267 = query.getOrDefault("Version")
  valid_773267 = validateParameter(valid_773267, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773267 != nil:
    section.add "Version", valid_773267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773268 = header.getOrDefault("X-Amz-Date")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Date", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Security-Token")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Security-Token", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Content-Sha256", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Algorithm")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Algorithm", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Signature")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Signature", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-SignedHeaders", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-Credential")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Credential", valid_773274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773275: Call_GetConfirmSubscription_773260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_773275.validator(path, query, header, formData, body)
  let scheme = call_773275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773275.url(scheme.get, call_773275.host, call_773275.base,
                         call_773275.route, valid.getOrDefault("path"))
  result = hook(call_773275, url, valid)

proc call*(call_773276: Call_GetConfirmSubscription_773260; Token: string;
          TopicArn: string; Action: string = "ConfirmSubscription";
          AuthenticateOnUnsubscribe: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Version: string (required)
  var query_773277 = newJObject()
  add(query_773277, "Token", newJString(Token))
  add(query_773277, "Action", newJString(Action))
  add(query_773277, "TopicArn", newJString(TopicArn))
  add(query_773277, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_773277, "Version", newJString(Version))
  result = call_773276.call(nil, query_773277, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_773260(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_773261, base: "/",
    url: url_GetConfirmSubscription_773262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_773320 = ref object of OpenApiRestCall_772597
proc url_PostCreatePlatformApplication_773322(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreatePlatformApplication_773321(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773323 = query.getOrDefault("Action")
  valid_773323 = validateParameter(valid_773323, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_773323 != nil:
    section.add "Action", valid_773323
  var valid_773324 = query.getOrDefault("Version")
  valid_773324 = validateParameter(valid_773324, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773324 != nil:
    section.add "Version", valid_773324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Content-Sha256", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Algorithm")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Algorithm", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Signature")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Signature", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-SignedHeaders", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Credential")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Credential", valid_773331
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_773332 = formData.getOrDefault("Name")
  valid_773332 = validateParameter(valid_773332, JString, required = true,
                                 default = nil)
  if valid_773332 != nil:
    section.add "Name", valid_773332
  var valid_773333 = formData.getOrDefault("Attributes.0.value")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "Attributes.0.value", valid_773333
  var valid_773334 = formData.getOrDefault("Attributes.0.key")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "Attributes.0.key", valid_773334
  var valid_773335 = formData.getOrDefault("Attributes.1.key")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "Attributes.1.key", valid_773335
  var valid_773336 = formData.getOrDefault("Attributes.2.value")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "Attributes.2.value", valid_773336
  var valid_773337 = formData.getOrDefault("Platform")
  valid_773337 = validateParameter(valid_773337, JString, required = true,
                                 default = nil)
  if valid_773337 != nil:
    section.add "Platform", valid_773337
  var valid_773338 = formData.getOrDefault("Attributes.2.key")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "Attributes.2.key", valid_773338
  var valid_773339 = formData.getOrDefault("Attributes.1.value")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "Attributes.1.value", valid_773339
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773340: Call_PostCreatePlatformApplication_773320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_773340.validator(path, query, header, formData, body)
  let scheme = call_773340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773340.url(scheme.get, call_773340.host, call_773340.base,
                         call_773340.route, valid.getOrDefault("path"))
  result = hook(call_773340, url, valid)

proc call*(call_773341: Call_PostCreatePlatformApplication_773320; Name: string;
          Platform: string; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformApplication";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_773342 = newJObject()
  var formData_773343 = newJObject()
  add(formData_773343, "Name", newJString(Name))
  add(formData_773343, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_773343, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_773343, "Attributes.1.key", newJString(Attributes1Key))
  add(query_773342, "Action", newJString(Action))
  add(formData_773343, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_773343, "Platform", newJString(Platform))
  add(formData_773343, "Attributes.2.key", newJString(Attributes2Key))
  add(query_773342, "Version", newJString(Version))
  add(formData_773343, "Attributes.1.value", newJString(Attributes1Value))
  result = call_773341.call(nil, query_773342, nil, formData_773343, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_773320(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_773321, base: "/",
    url: url_PostCreatePlatformApplication_773322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_773297 = ref object of OpenApiRestCall_772597
proc url_GetCreatePlatformApplication_773299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreatePlatformApplication_773298(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_773300 = query.getOrDefault("Attributes.2.key")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "Attributes.2.key", valid_773300
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_773301 = query.getOrDefault("Name")
  valid_773301 = validateParameter(valid_773301, JString, required = true,
                                 default = nil)
  if valid_773301 != nil:
    section.add "Name", valid_773301
  var valid_773302 = query.getOrDefault("Attributes.1.value")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "Attributes.1.value", valid_773302
  var valid_773303 = query.getOrDefault("Attributes.0.value")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "Attributes.0.value", valid_773303
  var valid_773304 = query.getOrDefault("Action")
  valid_773304 = validateParameter(valid_773304, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_773304 != nil:
    section.add "Action", valid_773304
  var valid_773305 = query.getOrDefault("Attributes.1.key")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "Attributes.1.key", valid_773305
  var valid_773306 = query.getOrDefault("Platform")
  valid_773306 = validateParameter(valid_773306, JString, required = true,
                                 default = nil)
  if valid_773306 != nil:
    section.add "Platform", valid_773306
  var valid_773307 = query.getOrDefault("Attributes.2.value")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "Attributes.2.value", valid_773307
  var valid_773308 = query.getOrDefault("Attributes.0.key")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "Attributes.0.key", valid_773308
  var valid_773309 = query.getOrDefault("Version")
  valid_773309 = validateParameter(valid_773309, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773309 != nil:
    section.add "Version", valid_773309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773310 = header.getOrDefault("X-Amz-Date")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Date", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Security-Token")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Security-Token", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Content-Sha256", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Algorithm")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Algorithm", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Signature")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Signature", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-SignedHeaders", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Credential")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Credential", valid_773316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773317: Call_GetCreatePlatformApplication_773297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_773317.validator(path, query, header, formData, body)
  let scheme = call_773317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773317.url(scheme.get, call_773317.host, call_773317.base,
                         call_773317.route, valid.getOrDefault("path"))
  result = hook(call_773317, url, valid)

proc call*(call_773318: Call_GetCreatePlatformApplication_773297; Name: string;
          Platform: string; Attributes2Key: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "CreatePlatformApplication"; Attributes1Key: string = "";
          Attributes2Value: string = ""; Attributes0Key: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ##   Attributes2Key: string
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_773319 = newJObject()
  add(query_773319, "Attributes.2.key", newJString(Attributes2Key))
  add(query_773319, "Name", newJString(Name))
  add(query_773319, "Attributes.1.value", newJString(Attributes1Value))
  add(query_773319, "Attributes.0.value", newJString(Attributes0Value))
  add(query_773319, "Action", newJString(Action))
  add(query_773319, "Attributes.1.key", newJString(Attributes1Key))
  add(query_773319, "Platform", newJString(Platform))
  add(query_773319, "Attributes.2.value", newJString(Attributes2Value))
  add(query_773319, "Attributes.0.key", newJString(Attributes0Key))
  add(query_773319, "Version", newJString(Version))
  result = call_773318.call(nil, query_773319, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_773297(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_773298, base: "/",
    url: url_GetCreatePlatformApplication_773299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_773368 = ref object of OpenApiRestCall_772597
proc url_PostCreatePlatformEndpoint_773370(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreatePlatformEndpoint_773369(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773371 = query.getOrDefault("Action")
  valid_773371 = validateParameter(valid_773371, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_773371 != nil:
    section.add "Action", valid_773371
  var valid_773372 = query.getOrDefault("Version")
  valid_773372 = validateParameter(valid_773372, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773372 != nil:
    section.add "Version", valid_773372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773373 = header.getOrDefault("X-Amz-Date")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Date", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Security-Token")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Security-Token", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Content-Sha256", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Algorithm")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Algorithm", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Signature")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Signature", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-SignedHeaders", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-Credential")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Credential", valid_773379
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  section = newJObject()
  var valid_773380 = formData.getOrDefault("Attributes.0.value")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "Attributes.0.value", valid_773380
  var valid_773381 = formData.getOrDefault("Attributes.0.key")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "Attributes.0.key", valid_773381
  var valid_773382 = formData.getOrDefault("Attributes.1.key")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "Attributes.1.key", valid_773382
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_773383 = formData.getOrDefault("PlatformApplicationArn")
  valid_773383 = validateParameter(valid_773383, JString, required = true,
                                 default = nil)
  if valid_773383 != nil:
    section.add "PlatformApplicationArn", valid_773383
  var valid_773384 = formData.getOrDefault("CustomUserData")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "CustomUserData", valid_773384
  var valid_773385 = formData.getOrDefault("Attributes.2.value")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "Attributes.2.value", valid_773385
  var valid_773386 = formData.getOrDefault("Attributes.2.key")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "Attributes.2.key", valid_773386
  var valid_773387 = formData.getOrDefault("Attributes.1.value")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "Attributes.1.value", valid_773387
  var valid_773388 = formData.getOrDefault("Token")
  valid_773388 = validateParameter(valid_773388, JString, required = true,
                                 default = nil)
  if valid_773388 != nil:
    section.add "Token", valid_773388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773389: Call_PostCreatePlatformEndpoint_773368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_773389.validator(path, query, header, formData, body)
  let scheme = call_773389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773389.url(scheme.get, call_773389.host, call_773389.base,
                         call_773389.route, valid.getOrDefault("path"))
  result = hook(call_773389, url, valid)

proc call*(call_773390: Call_PostCreatePlatformEndpoint_773368;
          PlatformApplicationArn: string; Token: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes1Key: string = ""; Action: string = "CreatePlatformEndpoint";
          CustomUserData: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  var query_773391 = newJObject()
  var formData_773392 = newJObject()
  add(formData_773392, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_773392, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_773392, "Attributes.1.key", newJString(Attributes1Key))
  add(query_773391, "Action", newJString(Action))
  add(formData_773392, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_773392, "CustomUserData", newJString(CustomUserData))
  add(formData_773392, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_773392, "Attributes.2.key", newJString(Attributes2Key))
  add(query_773391, "Version", newJString(Version))
  add(formData_773392, "Attributes.1.value", newJString(Attributes1Value))
  add(formData_773392, "Token", newJString(Token))
  result = call_773390.call(nil, query_773391, nil, formData_773392, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_773368(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_773369, base: "/",
    url: url_PostCreatePlatformEndpoint_773370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_773344 = ref object of OpenApiRestCall_772597
proc url_GetCreatePlatformEndpoint_773346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreatePlatformEndpoint_773345(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.2.key: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  section = newJObject()
  var valid_773347 = query.getOrDefault("CustomUserData")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "CustomUserData", valid_773347
  var valid_773348 = query.getOrDefault("Attributes.2.key")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "Attributes.2.key", valid_773348
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_773349 = query.getOrDefault("Token")
  valid_773349 = validateParameter(valid_773349, JString, required = true,
                                 default = nil)
  if valid_773349 != nil:
    section.add "Token", valid_773349
  var valid_773350 = query.getOrDefault("Attributes.1.value")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "Attributes.1.value", valid_773350
  var valid_773351 = query.getOrDefault("Attributes.0.value")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "Attributes.0.value", valid_773351
  var valid_773352 = query.getOrDefault("Action")
  valid_773352 = validateParameter(valid_773352, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_773352 != nil:
    section.add "Action", valid_773352
  var valid_773353 = query.getOrDefault("Attributes.1.key")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "Attributes.1.key", valid_773353
  var valid_773354 = query.getOrDefault("Attributes.2.value")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "Attributes.2.value", valid_773354
  var valid_773355 = query.getOrDefault("Attributes.0.key")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "Attributes.0.key", valid_773355
  var valid_773356 = query.getOrDefault("Version")
  valid_773356 = validateParameter(valid_773356, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773356 != nil:
    section.add "Version", valid_773356
  var valid_773357 = query.getOrDefault("PlatformApplicationArn")
  valid_773357 = validateParameter(valid_773357, JString, required = true,
                                 default = nil)
  if valid_773357 != nil:
    section.add "PlatformApplicationArn", valid_773357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773358 = header.getOrDefault("X-Amz-Date")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Date", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Security-Token")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Security-Token", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Content-Sha256", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Algorithm")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Algorithm", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Signature")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Signature", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-SignedHeaders", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Credential")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Credential", valid_773364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773365: Call_GetCreatePlatformEndpoint_773344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_773365.validator(path, query, header, formData, body)
  let scheme = call_773365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773365.url(scheme.get, call_773365.host, call_773365.base,
                         call_773365.route, valid.getOrDefault("path"))
  result = hook(call_773365, url, valid)

proc call*(call_773366: Call_GetCreatePlatformEndpoint_773344; Token: string;
          PlatformApplicationArn: string; CustomUserData: string = "";
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Attributes0Value: string = ""; Action: string = "CreatePlatformEndpoint";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes2Key: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  var query_773367 = newJObject()
  add(query_773367, "CustomUserData", newJString(CustomUserData))
  add(query_773367, "Attributes.2.key", newJString(Attributes2Key))
  add(query_773367, "Token", newJString(Token))
  add(query_773367, "Attributes.1.value", newJString(Attributes1Value))
  add(query_773367, "Attributes.0.value", newJString(Attributes0Value))
  add(query_773367, "Action", newJString(Action))
  add(query_773367, "Attributes.1.key", newJString(Attributes1Key))
  add(query_773367, "Attributes.2.value", newJString(Attributes2Value))
  add(query_773367, "Attributes.0.key", newJString(Attributes0Key))
  add(query_773367, "Version", newJString(Version))
  add(query_773367, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_773366.call(nil, query_773367, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_773344(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_773345, base: "/",
    url: url_GetCreatePlatformEndpoint_773346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_773416 = ref object of OpenApiRestCall_772597
proc url_PostCreateTopic_773418(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateTopic_773417(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773419 = query.getOrDefault("Action")
  valid_773419 = validateParameter(valid_773419, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_773419 != nil:
    section.add "Action", valid_773419
  var valid_773420 = query.getOrDefault("Version")
  valid_773420 = validateParameter(valid_773420, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773420 != nil:
    section.add "Version", valid_773420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773421 = header.getOrDefault("X-Amz-Date")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Date", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Security-Token")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Security-Token", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Content-Sha256", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Algorithm")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Algorithm", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Signature")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Signature", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-SignedHeaders", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Credential")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Credential", valid_773427
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_773428 = formData.getOrDefault("Name")
  valid_773428 = validateParameter(valid_773428, JString, required = true,
                                 default = nil)
  if valid_773428 != nil:
    section.add "Name", valid_773428
  var valid_773429 = formData.getOrDefault("Attributes.0.value")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "Attributes.0.value", valid_773429
  var valid_773430 = formData.getOrDefault("Attributes.0.key")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "Attributes.0.key", valid_773430
  var valid_773431 = formData.getOrDefault("Tags")
  valid_773431 = validateParameter(valid_773431, JArray, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "Tags", valid_773431
  var valid_773432 = formData.getOrDefault("Attributes.1.key")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "Attributes.1.key", valid_773432
  var valid_773433 = formData.getOrDefault("Attributes.2.value")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "Attributes.2.value", valid_773433
  var valid_773434 = formData.getOrDefault("Attributes.2.key")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "Attributes.2.key", valid_773434
  var valid_773435 = formData.getOrDefault("Attributes.1.value")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "Attributes.1.value", valid_773435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773436: Call_PostCreateTopic_773416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_773436.validator(path, query, header, formData, body)
  let scheme = call_773436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773436.url(scheme.get, call_773436.host, call_773436.base,
                         call_773436.route, valid.getOrDefault("path"))
  result = hook(call_773436, url, valid)

proc call*(call_773437: Call_PostCreateTopic_773416; Name: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Tags: JsonNode = nil; Attributes1Key: string = "";
          Action: string = "CreateTopic"; Attributes2Value: string = "";
          Attributes2Key: string = ""; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_773438 = newJObject()
  var formData_773439 = newJObject()
  add(formData_773439, "Name", newJString(Name))
  add(formData_773439, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_773439, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    formData_773439.add "Tags", Tags
  add(formData_773439, "Attributes.1.key", newJString(Attributes1Key))
  add(query_773438, "Action", newJString(Action))
  add(formData_773439, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_773439, "Attributes.2.key", newJString(Attributes2Key))
  add(query_773438, "Version", newJString(Version))
  add(formData_773439, "Attributes.1.value", newJString(Attributes1Value))
  result = call_773437.call(nil, query_773438, nil, formData_773439, nil)

var postCreateTopic* = Call_PostCreateTopic_773416(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_773417,
    base: "/", url: url_PostCreateTopic_773418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_773393 = ref object of OpenApiRestCall_772597
proc url_GetCreateTopic_773395(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateTopic_773394(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes.1.value: JString
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_773396 = query.getOrDefault("Attributes.2.key")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "Attributes.2.key", valid_773396
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_773397 = query.getOrDefault("Name")
  valid_773397 = validateParameter(valid_773397, JString, required = true,
                                 default = nil)
  if valid_773397 != nil:
    section.add "Name", valid_773397
  var valid_773398 = query.getOrDefault("Attributes.1.value")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "Attributes.1.value", valid_773398
  var valid_773399 = query.getOrDefault("Tags")
  valid_773399 = validateParameter(valid_773399, JArray, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "Tags", valid_773399
  var valid_773400 = query.getOrDefault("Attributes.0.value")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "Attributes.0.value", valid_773400
  var valid_773401 = query.getOrDefault("Action")
  valid_773401 = validateParameter(valid_773401, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_773401 != nil:
    section.add "Action", valid_773401
  var valid_773402 = query.getOrDefault("Attributes.1.key")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "Attributes.1.key", valid_773402
  var valid_773403 = query.getOrDefault("Attributes.2.value")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "Attributes.2.value", valid_773403
  var valid_773404 = query.getOrDefault("Attributes.0.key")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "Attributes.0.key", valid_773404
  var valid_773405 = query.getOrDefault("Version")
  valid_773405 = validateParameter(valid_773405, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773405 != nil:
    section.add "Version", valid_773405
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773406 = header.getOrDefault("X-Amz-Date")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Date", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Security-Token")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Security-Token", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Content-Sha256", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Algorithm")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Algorithm", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Signature")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Signature", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-SignedHeaders", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Credential")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Credential", valid_773412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773413: Call_GetCreateTopic_773393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_773413.validator(path, query, header, formData, body)
  let scheme = call_773413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773413.url(scheme.get, call_773413.host, call_773413.base,
                         call_773413.route, valid.getOrDefault("path"))
  result = hook(call_773413, url, valid)

proc call*(call_773414: Call_GetCreateTopic_773393; Name: string;
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Tags: JsonNode = nil; Attributes0Value: string = "";
          Action: string = "CreateTopic"; Attributes1Key: string = "";
          Attributes2Value: string = ""; Attributes0Key: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Attributes2Key: string
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes1Value: string
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_773415 = newJObject()
  add(query_773415, "Attributes.2.key", newJString(Attributes2Key))
  add(query_773415, "Name", newJString(Name))
  add(query_773415, "Attributes.1.value", newJString(Attributes1Value))
  if Tags != nil:
    query_773415.add "Tags", Tags
  add(query_773415, "Attributes.0.value", newJString(Attributes0Value))
  add(query_773415, "Action", newJString(Action))
  add(query_773415, "Attributes.1.key", newJString(Attributes1Key))
  add(query_773415, "Attributes.2.value", newJString(Attributes2Value))
  add(query_773415, "Attributes.0.key", newJString(Attributes0Key))
  add(query_773415, "Version", newJString(Version))
  result = call_773414.call(nil, query_773415, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_773393(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_773394,
    base: "/", url: url_GetCreateTopic_773395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_773456 = ref object of OpenApiRestCall_772597
proc url_PostDeleteEndpoint_773458(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEndpoint_773457(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773459 = query.getOrDefault("Action")
  valid_773459 = validateParameter(valid_773459, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_773459 != nil:
    section.add "Action", valid_773459
  var valid_773460 = query.getOrDefault("Version")
  valid_773460 = validateParameter(valid_773460, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773460 != nil:
    section.add "Version", valid_773460
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773461 = header.getOrDefault("X-Amz-Date")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Date", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-Security-Token")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Security-Token", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Content-Sha256", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Algorithm")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Algorithm", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Signature")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Signature", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-SignedHeaders", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Credential")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Credential", valid_773467
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_773468 = formData.getOrDefault("EndpointArn")
  valid_773468 = validateParameter(valid_773468, JString, required = true,
                                 default = nil)
  if valid_773468 != nil:
    section.add "EndpointArn", valid_773468
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773469: Call_PostDeleteEndpoint_773456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_773469.validator(path, query, header, formData, body)
  let scheme = call_773469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773469.url(scheme.get, call_773469.host, call_773469.base,
                         call_773469.route, valid.getOrDefault("path"))
  result = hook(call_773469, url, valid)

proc call*(call_773470: Call_PostDeleteEndpoint_773456; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_773471 = newJObject()
  var formData_773472 = newJObject()
  add(query_773471, "Action", newJString(Action))
  add(formData_773472, "EndpointArn", newJString(EndpointArn))
  add(query_773471, "Version", newJString(Version))
  result = call_773470.call(nil, query_773471, nil, formData_773472, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_773456(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_773457, base: "/",
    url: url_PostDeleteEndpoint_773458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_773440 = ref object of OpenApiRestCall_772597
proc url_GetDeleteEndpoint_773442(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEndpoint_773441(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EndpointArn` field"
  var valid_773443 = query.getOrDefault("EndpointArn")
  valid_773443 = validateParameter(valid_773443, JString, required = true,
                                 default = nil)
  if valid_773443 != nil:
    section.add "EndpointArn", valid_773443
  var valid_773444 = query.getOrDefault("Action")
  valid_773444 = validateParameter(valid_773444, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_773444 != nil:
    section.add "Action", valid_773444
  var valid_773445 = query.getOrDefault("Version")
  valid_773445 = validateParameter(valid_773445, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773445 != nil:
    section.add "Version", valid_773445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773446 = header.getOrDefault("X-Amz-Date")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Date", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Security-Token")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Security-Token", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Content-Sha256", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Algorithm")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Algorithm", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Signature")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Signature", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-SignedHeaders", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Credential")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Credential", valid_773452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773453: Call_GetDeleteEndpoint_773440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_773453.validator(path, query, header, formData, body)
  let scheme = call_773453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773453.url(scheme.get, call_773453.host, call_773453.base,
                         call_773453.route, valid.getOrDefault("path"))
  result = hook(call_773453, url, valid)

proc call*(call_773454: Call_GetDeleteEndpoint_773440; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773455 = newJObject()
  add(query_773455, "EndpointArn", newJString(EndpointArn))
  add(query_773455, "Action", newJString(Action))
  add(query_773455, "Version", newJString(Version))
  result = call_773454.call(nil, query_773455, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_773440(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_773441,
    base: "/", url: url_GetDeleteEndpoint_773442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_773489 = ref object of OpenApiRestCall_772597
proc url_PostDeletePlatformApplication_773491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeletePlatformApplication_773490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773492 = query.getOrDefault("Action")
  valid_773492 = validateParameter(valid_773492, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_773492 != nil:
    section.add "Action", valid_773492
  var valid_773493 = query.getOrDefault("Version")
  valid_773493 = validateParameter(valid_773493, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773493 != nil:
    section.add "Version", valid_773493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773494 = header.getOrDefault("X-Amz-Date")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Date", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Security-Token")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Security-Token", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Content-Sha256", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Algorithm")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Algorithm", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-Signature")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Signature", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-SignedHeaders", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Credential")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Credential", valid_773500
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_773501 = formData.getOrDefault("PlatformApplicationArn")
  valid_773501 = validateParameter(valid_773501, JString, required = true,
                                 default = nil)
  if valid_773501 != nil:
    section.add "PlatformApplicationArn", valid_773501
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773502: Call_PostDeletePlatformApplication_773489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_773502.validator(path, query, header, formData, body)
  let scheme = call_773502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773502.url(scheme.get, call_773502.host, call_773502.base,
                         call_773502.route, valid.getOrDefault("path"))
  result = hook(call_773502, url, valid)

proc call*(call_773503: Call_PostDeletePlatformApplication_773489;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Version: string (required)
  var query_773504 = newJObject()
  var formData_773505 = newJObject()
  add(query_773504, "Action", newJString(Action))
  add(formData_773505, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_773504, "Version", newJString(Version))
  result = call_773503.call(nil, query_773504, nil, formData_773505, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_773489(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_773490, base: "/",
    url: url_PostDeletePlatformApplication_773491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_773473 = ref object of OpenApiRestCall_772597
proc url_GetDeletePlatformApplication_773475(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeletePlatformApplication_773474(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773476 = query.getOrDefault("Action")
  valid_773476 = validateParameter(valid_773476, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_773476 != nil:
    section.add "Action", valid_773476
  var valid_773477 = query.getOrDefault("Version")
  valid_773477 = validateParameter(valid_773477, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773477 != nil:
    section.add "Version", valid_773477
  var valid_773478 = query.getOrDefault("PlatformApplicationArn")
  valid_773478 = validateParameter(valid_773478, JString, required = true,
                                 default = nil)
  if valid_773478 != nil:
    section.add "PlatformApplicationArn", valid_773478
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773479 = header.getOrDefault("X-Amz-Date")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Date", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Security-Token")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Security-Token", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Content-Sha256", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Algorithm")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Algorithm", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Signature")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Signature", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-SignedHeaders", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Credential")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Credential", valid_773485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773486: Call_GetDeletePlatformApplication_773473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_773486.validator(path, query, header, formData, body)
  let scheme = call_773486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773486.url(scheme.get, call_773486.host, call_773486.base,
                         call_773486.route, valid.getOrDefault("path"))
  result = hook(call_773486, url, valid)

proc call*(call_773487: Call_GetDeletePlatformApplication_773473;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  var query_773488 = newJObject()
  add(query_773488, "Action", newJString(Action))
  add(query_773488, "Version", newJString(Version))
  add(query_773488, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_773487.call(nil, query_773488, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_773473(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_773474, base: "/",
    url: url_GetDeletePlatformApplication_773475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_773522 = ref object of OpenApiRestCall_772597
proc url_PostDeleteTopic_773524(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteTopic_773523(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773525 = query.getOrDefault("Action")
  valid_773525 = validateParameter(valid_773525, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_773525 != nil:
    section.add "Action", valid_773525
  var valid_773526 = query.getOrDefault("Version")
  valid_773526 = validateParameter(valid_773526, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773526 != nil:
    section.add "Version", valid_773526
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773527 = header.getOrDefault("X-Amz-Date")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Date", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Security-Token")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Security-Token", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Content-Sha256", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Algorithm")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Algorithm", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Signature")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Signature", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-SignedHeaders", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Credential")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Credential", valid_773533
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_773534 = formData.getOrDefault("TopicArn")
  valid_773534 = validateParameter(valid_773534, JString, required = true,
                                 default = nil)
  if valid_773534 != nil:
    section.add "TopicArn", valid_773534
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773535: Call_PostDeleteTopic_773522; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_773535.validator(path, query, header, formData, body)
  let scheme = call_773535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773535.url(scheme.get, call_773535.host, call_773535.base,
                         call_773535.route, valid.getOrDefault("path"))
  result = hook(call_773535, url, valid)

proc call*(call_773536: Call_PostDeleteTopic_773522; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773537 = newJObject()
  var formData_773538 = newJObject()
  add(formData_773538, "TopicArn", newJString(TopicArn))
  add(query_773537, "Action", newJString(Action))
  add(query_773537, "Version", newJString(Version))
  result = call_773536.call(nil, query_773537, nil, formData_773538, nil)

var postDeleteTopic* = Call_PostDeleteTopic_773522(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_773523,
    base: "/", url: url_PostDeleteTopic_773524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_773506 = ref object of OpenApiRestCall_772597
proc url_GetDeleteTopic_773508(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteTopic_773507(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773509 = query.getOrDefault("Action")
  valid_773509 = validateParameter(valid_773509, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_773509 != nil:
    section.add "Action", valid_773509
  var valid_773510 = query.getOrDefault("TopicArn")
  valid_773510 = validateParameter(valid_773510, JString, required = true,
                                 default = nil)
  if valid_773510 != nil:
    section.add "TopicArn", valid_773510
  var valid_773511 = query.getOrDefault("Version")
  valid_773511 = validateParameter(valid_773511, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773511 != nil:
    section.add "Version", valid_773511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773512 = header.getOrDefault("X-Amz-Date")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Date", valid_773512
  var valid_773513 = header.getOrDefault("X-Amz-Security-Token")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "X-Amz-Security-Token", valid_773513
  var valid_773514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-Content-Sha256", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Algorithm")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Algorithm", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Signature")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Signature", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-SignedHeaders", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Credential")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Credential", valid_773518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773519: Call_GetDeleteTopic_773506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_773519.validator(path, query, header, formData, body)
  let scheme = call_773519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773519.url(scheme.get, call_773519.host, call_773519.base,
                         call_773519.route, valid.getOrDefault("path"))
  result = hook(call_773519, url, valid)

proc call*(call_773520: Call_GetDeleteTopic_773506; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: string (required)
  var query_773521 = newJObject()
  add(query_773521, "Action", newJString(Action))
  add(query_773521, "TopicArn", newJString(TopicArn))
  add(query_773521, "Version", newJString(Version))
  result = call_773520.call(nil, query_773521, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_773506(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_773507,
    base: "/", url: url_GetDeleteTopic_773508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_773555 = ref object of OpenApiRestCall_772597
proc url_PostGetEndpointAttributes_773557(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetEndpointAttributes_773556(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773558 = query.getOrDefault("Action")
  valid_773558 = validateParameter(valid_773558, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_773558 != nil:
    section.add "Action", valid_773558
  var valid_773559 = query.getOrDefault("Version")
  valid_773559 = validateParameter(valid_773559, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773559 != nil:
    section.add "Version", valid_773559
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773560 = header.getOrDefault("X-Amz-Date")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Date", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Security-Token")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Security-Token", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Content-Sha256", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Algorithm")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Algorithm", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Signature")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Signature", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-SignedHeaders", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Credential")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Credential", valid_773566
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_773567 = formData.getOrDefault("EndpointArn")
  valid_773567 = validateParameter(valid_773567, JString, required = true,
                                 default = nil)
  if valid_773567 != nil:
    section.add "EndpointArn", valid_773567
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773568: Call_PostGetEndpointAttributes_773555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_773568.validator(path, query, header, formData, body)
  let scheme = call_773568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773568.url(scheme.get, call_773568.host, call_773568.base,
                         call_773568.route, valid.getOrDefault("path"))
  result = hook(call_773568, url, valid)

proc call*(call_773569: Call_PostGetEndpointAttributes_773555; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_773570 = newJObject()
  var formData_773571 = newJObject()
  add(query_773570, "Action", newJString(Action))
  add(formData_773571, "EndpointArn", newJString(EndpointArn))
  add(query_773570, "Version", newJString(Version))
  result = call_773569.call(nil, query_773570, nil, formData_773571, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_773555(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_773556, base: "/",
    url: url_PostGetEndpointAttributes_773557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_773539 = ref object of OpenApiRestCall_772597
proc url_GetGetEndpointAttributes_773541(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetEndpointAttributes_773540(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EndpointArn` field"
  var valid_773542 = query.getOrDefault("EndpointArn")
  valid_773542 = validateParameter(valid_773542, JString, required = true,
                                 default = nil)
  if valid_773542 != nil:
    section.add "EndpointArn", valid_773542
  var valid_773543 = query.getOrDefault("Action")
  valid_773543 = validateParameter(valid_773543, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_773543 != nil:
    section.add "Action", valid_773543
  var valid_773544 = query.getOrDefault("Version")
  valid_773544 = validateParameter(valid_773544, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773544 != nil:
    section.add "Version", valid_773544
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773545 = header.getOrDefault("X-Amz-Date")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Date", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Security-Token")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Security-Token", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Content-Sha256", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Algorithm")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Algorithm", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Signature")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Signature", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-SignedHeaders", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Credential")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Credential", valid_773551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773552: Call_GetGetEndpointAttributes_773539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_773552.validator(path, query, header, formData, body)
  let scheme = call_773552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773552.url(scheme.get, call_773552.host, call_773552.base,
                         call_773552.route, valid.getOrDefault("path"))
  result = hook(call_773552, url, valid)

proc call*(call_773553: Call_GetGetEndpointAttributes_773539; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773554 = newJObject()
  add(query_773554, "EndpointArn", newJString(EndpointArn))
  add(query_773554, "Action", newJString(Action))
  add(query_773554, "Version", newJString(Version))
  result = call_773553.call(nil, query_773554, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_773539(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_773540, base: "/",
    url: url_GetGetEndpointAttributes_773541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_773588 = ref object of OpenApiRestCall_772597
proc url_PostGetPlatformApplicationAttributes_773590(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetPlatformApplicationAttributes_773589(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773591 = query.getOrDefault("Action")
  valid_773591 = validateParameter(valid_773591, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_773591 != nil:
    section.add "Action", valid_773591
  var valid_773592 = query.getOrDefault("Version")
  valid_773592 = validateParameter(valid_773592, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773592 != nil:
    section.add "Version", valid_773592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773593 = header.getOrDefault("X-Amz-Date")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Date", valid_773593
  var valid_773594 = header.getOrDefault("X-Amz-Security-Token")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Security-Token", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Content-Sha256", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Algorithm")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Algorithm", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-Signature")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Signature", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-SignedHeaders", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Credential")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Credential", valid_773599
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_773600 = formData.getOrDefault("PlatformApplicationArn")
  valid_773600 = validateParameter(valid_773600, JString, required = true,
                                 default = nil)
  if valid_773600 != nil:
    section.add "PlatformApplicationArn", valid_773600
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773601: Call_PostGetPlatformApplicationAttributes_773588;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_773601.validator(path, query, header, formData, body)
  let scheme = call_773601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773601.url(scheme.get, call_773601.host, call_773601.base,
                         call_773601.route, valid.getOrDefault("path"))
  result = hook(call_773601, url, valid)

proc call*(call_773602: Call_PostGetPlatformApplicationAttributes_773588;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Version: string (required)
  var query_773603 = newJObject()
  var formData_773604 = newJObject()
  add(query_773603, "Action", newJString(Action))
  add(formData_773604, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_773603, "Version", newJString(Version))
  result = call_773602.call(nil, query_773603, nil, formData_773604, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_773588(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_773589, base: "/",
    url: url_PostGetPlatformApplicationAttributes_773590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_773572 = ref object of OpenApiRestCall_772597
proc url_GetGetPlatformApplicationAttributes_773574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetPlatformApplicationAttributes_773573(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773575 = query.getOrDefault("Action")
  valid_773575 = validateParameter(valid_773575, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_773575 != nil:
    section.add "Action", valid_773575
  var valid_773576 = query.getOrDefault("Version")
  valid_773576 = validateParameter(valid_773576, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773576 != nil:
    section.add "Version", valid_773576
  var valid_773577 = query.getOrDefault("PlatformApplicationArn")
  valid_773577 = validateParameter(valid_773577, JString, required = true,
                                 default = nil)
  if valid_773577 != nil:
    section.add "PlatformApplicationArn", valid_773577
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773578 = header.getOrDefault("X-Amz-Date")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Date", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Security-Token")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Security-Token", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Content-Sha256", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Algorithm")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Algorithm", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-Signature")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-Signature", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-SignedHeaders", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Credential")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Credential", valid_773584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773585: Call_GetGetPlatformApplicationAttributes_773572;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_773585.validator(path, query, header, formData, body)
  let scheme = call_773585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773585.url(scheme.get, call_773585.host, call_773585.base,
                         call_773585.route, valid.getOrDefault("path"))
  result = hook(call_773585, url, valid)

proc call*(call_773586: Call_GetGetPlatformApplicationAttributes_773572;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  var query_773587 = newJObject()
  add(query_773587, "Action", newJString(Action))
  add(query_773587, "Version", newJString(Version))
  add(query_773587, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_773586.call(nil, query_773587, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_773572(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_773573, base: "/",
    url: url_GetGetPlatformApplicationAttributes_773574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_773621 = ref object of OpenApiRestCall_772597
proc url_PostGetSMSAttributes_773623(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetSMSAttributes_773622(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773624 = query.getOrDefault("Action")
  valid_773624 = validateParameter(valid_773624, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_773624 != nil:
    section.add "Action", valid_773624
  var valid_773625 = query.getOrDefault("Version")
  valid_773625 = validateParameter(valid_773625, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773625 != nil:
    section.add "Version", valid_773625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773626 = header.getOrDefault("X-Amz-Date")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Date", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-Security-Token")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-Security-Token", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Content-Sha256", valid_773628
  var valid_773629 = header.getOrDefault("X-Amz-Algorithm")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Algorithm", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Signature")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Signature", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-SignedHeaders", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Credential")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Credential", valid_773632
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_773633 = formData.getOrDefault("attributes")
  valid_773633 = validateParameter(valid_773633, JArray, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "attributes", valid_773633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773634: Call_PostGetSMSAttributes_773621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_773634.validator(path, query, header, formData, body)
  let scheme = call_773634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773634.url(scheme.get, call_773634.host, call_773634.base,
                         call_773634.route, valid.getOrDefault("path"))
  result = hook(call_773634, url, valid)

proc call*(call_773635: Call_PostGetSMSAttributes_773621;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773636 = newJObject()
  var formData_773637 = newJObject()
  if attributes != nil:
    formData_773637.add "attributes", attributes
  add(query_773636, "Action", newJString(Action))
  add(query_773636, "Version", newJString(Version))
  result = call_773635.call(nil, query_773636, nil, formData_773637, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_773621(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_773622, base: "/",
    url: url_PostGetSMSAttributes_773623, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_773605 = ref object of OpenApiRestCall_772597
proc url_GetGetSMSAttributes_773607(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetSMSAttributes_773606(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_773608 = query.getOrDefault("attributes")
  valid_773608 = validateParameter(valid_773608, JArray, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "attributes", valid_773608
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773609 = query.getOrDefault("Action")
  valid_773609 = validateParameter(valid_773609, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_773609 != nil:
    section.add "Action", valid_773609
  var valid_773610 = query.getOrDefault("Version")
  valid_773610 = validateParameter(valid_773610, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773610 != nil:
    section.add "Version", valid_773610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773611 = header.getOrDefault("X-Amz-Date")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Date", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-Security-Token")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Security-Token", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Content-Sha256", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Algorithm")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Algorithm", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Signature")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Signature", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-SignedHeaders", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Credential")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Credential", valid_773617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773618: Call_GetGetSMSAttributes_773605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_773618.validator(path, query, header, formData, body)
  let scheme = call_773618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773618.url(scheme.get, call_773618.host, call_773618.base,
                         call_773618.route, valid.getOrDefault("path"))
  result = hook(call_773618, url, valid)

proc call*(call_773619: Call_GetGetSMSAttributes_773605;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773620 = newJObject()
  if attributes != nil:
    query_773620.add "attributes", attributes
  add(query_773620, "Action", newJString(Action))
  add(query_773620, "Version", newJString(Version))
  result = call_773619.call(nil, query_773620, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_773605(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_773606, base: "/",
    url: url_GetGetSMSAttributes_773607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_773654 = ref object of OpenApiRestCall_772597
proc url_PostGetSubscriptionAttributes_773656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetSubscriptionAttributes_773655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773657 = query.getOrDefault("Action")
  valid_773657 = validateParameter(valid_773657, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_773657 != nil:
    section.add "Action", valid_773657
  var valid_773658 = query.getOrDefault("Version")
  valid_773658 = validateParameter(valid_773658, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773658 != nil:
    section.add "Version", valid_773658
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773659 = header.getOrDefault("X-Amz-Date")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Date", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Security-Token")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Security-Token", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Content-Sha256", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Algorithm")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Algorithm", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Signature")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Signature", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-SignedHeaders", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Credential")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Credential", valid_773665
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_773666 = formData.getOrDefault("SubscriptionArn")
  valid_773666 = validateParameter(valid_773666, JString, required = true,
                                 default = nil)
  if valid_773666 != nil:
    section.add "SubscriptionArn", valid_773666
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773667: Call_PostGetSubscriptionAttributes_773654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_773667.validator(path, query, header, formData, body)
  let scheme = call_773667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773667.url(scheme.get, call_773667.host, call_773667.base,
                         call_773667.route, valid.getOrDefault("path"))
  result = hook(call_773667, url, valid)

proc call*(call_773668: Call_PostGetSubscriptionAttributes_773654;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Version: string (required)
  var query_773669 = newJObject()
  var formData_773670 = newJObject()
  add(query_773669, "Action", newJString(Action))
  add(formData_773670, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_773669, "Version", newJString(Version))
  result = call_773668.call(nil, query_773669, nil, formData_773670, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_773654(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_773655, base: "/",
    url: url_PostGetSubscriptionAttributes_773656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_773638 = ref object of OpenApiRestCall_772597
proc url_GetGetSubscriptionAttributes_773640(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetSubscriptionAttributes_773639(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_773641 = query.getOrDefault("SubscriptionArn")
  valid_773641 = validateParameter(valid_773641, JString, required = true,
                                 default = nil)
  if valid_773641 != nil:
    section.add "SubscriptionArn", valid_773641
  var valid_773642 = query.getOrDefault("Action")
  valid_773642 = validateParameter(valid_773642, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_773642 != nil:
    section.add "Action", valid_773642
  var valid_773643 = query.getOrDefault("Version")
  valid_773643 = validateParameter(valid_773643, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773643 != nil:
    section.add "Version", valid_773643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773644 = header.getOrDefault("X-Amz-Date")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Date", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Security-Token")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Security-Token", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Content-Sha256", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Algorithm")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Algorithm", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Signature")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Signature", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-SignedHeaders", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Credential")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Credential", valid_773650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773651: Call_GetGetSubscriptionAttributes_773638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_773651.validator(path, query, header, formData, body)
  let scheme = call_773651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773651.url(scheme.get, call_773651.host, call_773651.base,
                         call_773651.route, valid.getOrDefault("path"))
  result = hook(call_773651, url, valid)

proc call*(call_773652: Call_GetGetSubscriptionAttributes_773638;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773653 = newJObject()
  add(query_773653, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_773653, "Action", newJString(Action))
  add(query_773653, "Version", newJString(Version))
  result = call_773652.call(nil, query_773653, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_773638(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_773639, base: "/",
    url: url_GetGetSubscriptionAttributes_773640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_773687 = ref object of OpenApiRestCall_772597
proc url_PostGetTopicAttributes_773689(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetTopicAttributes_773688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773690 = query.getOrDefault("Action")
  valid_773690 = validateParameter(valid_773690, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_773690 != nil:
    section.add "Action", valid_773690
  var valid_773691 = query.getOrDefault("Version")
  valid_773691 = validateParameter(valid_773691, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773691 != nil:
    section.add "Version", valid_773691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773692 = header.getOrDefault("X-Amz-Date")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Date", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Security-Token")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Security-Token", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Content-Sha256", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Algorithm")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Algorithm", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Signature")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Signature", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-SignedHeaders", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-Credential")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-Credential", valid_773698
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_773699 = formData.getOrDefault("TopicArn")
  valid_773699 = validateParameter(valid_773699, JString, required = true,
                                 default = nil)
  if valid_773699 != nil:
    section.add "TopicArn", valid_773699
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773700: Call_PostGetTopicAttributes_773687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_773700.validator(path, query, header, formData, body)
  let scheme = call_773700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773700.url(scheme.get, call_773700.host, call_773700.base,
                         call_773700.route, valid.getOrDefault("path"))
  result = hook(call_773700, url, valid)

proc call*(call_773701: Call_PostGetTopicAttributes_773687; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773702 = newJObject()
  var formData_773703 = newJObject()
  add(formData_773703, "TopicArn", newJString(TopicArn))
  add(query_773702, "Action", newJString(Action))
  add(query_773702, "Version", newJString(Version))
  result = call_773701.call(nil, query_773702, nil, formData_773703, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_773687(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_773688, base: "/",
    url: url_PostGetTopicAttributes_773689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_773671 = ref object of OpenApiRestCall_772597
proc url_GetGetTopicAttributes_773673(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetTopicAttributes_773672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773674 = query.getOrDefault("Action")
  valid_773674 = validateParameter(valid_773674, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_773674 != nil:
    section.add "Action", valid_773674
  var valid_773675 = query.getOrDefault("TopicArn")
  valid_773675 = validateParameter(valid_773675, JString, required = true,
                                 default = nil)
  if valid_773675 != nil:
    section.add "TopicArn", valid_773675
  var valid_773676 = query.getOrDefault("Version")
  valid_773676 = validateParameter(valid_773676, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773676 != nil:
    section.add "Version", valid_773676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773677 = header.getOrDefault("X-Amz-Date")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Date", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Security-Token")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Security-Token", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Content-Sha256", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Algorithm")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Algorithm", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Signature")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Signature", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-SignedHeaders", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Credential")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Credential", valid_773683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773684: Call_GetGetTopicAttributes_773671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_773684.validator(path, query, header, formData, body)
  let scheme = call_773684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773684.url(scheme.get, call_773684.host, call_773684.base,
                         call_773684.route, valid.getOrDefault("path"))
  result = hook(call_773684, url, valid)

proc call*(call_773685: Call_GetGetTopicAttributes_773671; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: string (required)
  var query_773686 = newJObject()
  add(query_773686, "Action", newJString(Action))
  add(query_773686, "TopicArn", newJString(TopicArn))
  add(query_773686, "Version", newJString(Version))
  result = call_773685.call(nil, query_773686, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_773671(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_773672, base: "/",
    url: url_GetGetTopicAttributes_773673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_773721 = ref object of OpenApiRestCall_772597
proc url_PostListEndpointsByPlatformApplication_773723(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListEndpointsByPlatformApplication_773722(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773724 = query.getOrDefault("Action")
  valid_773724 = validateParameter(valid_773724, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_773724 != nil:
    section.add "Action", valid_773724
  var valid_773725 = query.getOrDefault("Version")
  valid_773725 = validateParameter(valid_773725, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773725 != nil:
    section.add "Version", valid_773725
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773726 = header.getOrDefault("X-Amz-Date")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-Date", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Security-Token")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Security-Token", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Content-Sha256", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-Algorithm")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-Algorithm", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-Signature")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Signature", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-SignedHeaders", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-Credential")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-Credential", valid_773732
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_773733 = formData.getOrDefault("NextToken")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "NextToken", valid_773733
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_773734 = formData.getOrDefault("PlatformApplicationArn")
  valid_773734 = validateParameter(valid_773734, JString, required = true,
                                 default = nil)
  if valid_773734 != nil:
    section.add "PlatformApplicationArn", valid_773734
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773735: Call_PostListEndpointsByPlatformApplication_773721;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_773735.validator(path, query, header, formData, body)
  let scheme = call_773735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773735.url(scheme.get, call_773735.host, call_773735.base,
                         call_773735.route, valid.getOrDefault("path"))
  result = hook(call_773735, url, valid)

proc call*(call_773736: Call_PostListEndpointsByPlatformApplication_773721;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Version: string (required)
  var query_773737 = newJObject()
  var formData_773738 = newJObject()
  add(formData_773738, "NextToken", newJString(NextToken))
  add(query_773737, "Action", newJString(Action))
  add(formData_773738, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_773737, "Version", newJString(Version))
  result = call_773736.call(nil, query_773737, nil, formData_773738, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_773721(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_773722, base: "/",
    url: url_PostListEndpointsByPlatformApplication_773723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_773704 = ref object of OpenApiRestCall_772597
proc url_GetListEndpointsByPlatformApplication_773706(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListEndpointsByPlatformApplication_773705(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_773707 = query.getOrDefault("NextToken")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "NextToken", valid_773707
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773708 = query.getOrDefault("Action")
  valid_773708 = validateParameter(valid_773708, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_773708 != nil:
    section.add "Action", valid_773708
  var valid_773709 = query.getOrDefault("Version")
  valid_773709 = validateParameter(valid_773709, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773709 != nil:
    section.add "Version", valid_773709
  var valid_773710 = query.getOrDefault("PlatformApplicationArn")
  valid_773710 = validateParameter(valid_773710, JString, required = true,
                                 default = nil)
  if valid_773710 != nil:
    section.add "PlatformApplicationArn", valid_773710
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773711 = header.getOrDefault("X-Amz-Date")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Date", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-Security-Token")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Security-Token", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Content-Sha256", valid_773713
  var valid_773714 = header.getOrDefault("X-Amz-Algorithm")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-Algorithm", valid_773714
  var valid_773715 = header.getOrDefault("X-Amz-Signature")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Signature", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-SignedHeaders", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-Credential")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-Credential", valid_773717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773718: Call_GetListEndpointsByPlatformApplication_773704;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_773718.validator(path, query, header, formData, body)
  let scheme = call_773718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773718.url(scheme.get, call_773718.host, call_773718.base,
                         call_773718.route, valid.getOrDefault("path"))
  result = hook(call_773718, url, valid)

proc call*(call_773719: Call_GetListEndpointsByPlatformApplication_773704;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  var query_773720 = newJObject()
  add(query_773720, "NextToken", newJString(NextToken))
  add(query_773720, "Action", newJString(Action))
  add(query_773720, "Version", newJString(Version))
  add(query_773720, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_773719.call(nil, query_773720, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_773704(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_773705, base: "/",
    url: url_GetListEndpointsByPlatformApplication_773706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_773755 = ref object of OpenApiRestCall_772597
proc url_PostListPhoneNumbersOptedOut_773757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListPhoneNumbersOptedOut_773756(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773758 = query.getOrDefault("Action")
  valid_773758 = validateParameter(valid_773758, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_773758 != nil:
    section.add "Action", valid_773758
  var valid_773759 = query.getOrDefault("Version")
  valid_773759 = validateParameter(valid_773759, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773759 != nil:
    section.add "Version", valid_773759
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773760 = header.getOrDefault("X-Amz-Date")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Date", valid_773760
  var valid_773761 = header.getOrDefault("X-Amz-Security-Token")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-Security-Token", valid_773761
  var valid_773762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-Content-Sha256", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Algorithm")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Algorithm", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Signature")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Signature", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-SignedHeaders", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Credential")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Credential", valid_773766
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_773767 = formData.getOrDefault("nextToken")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "nextToken", valid_773767
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773768: Call_PostListPhoneNumbersOptedOut_773755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_773768.validator(path, query, header, formData, body)
  let scheme = call_773768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773768.url(scheme.get, call_773768.host, call_773768.base,
                         call_773768.route, valid.getOrDefault("path"))
  result = hook(call_773768, url, valid)

proc call*(call_773769: Call_PostListPhoneNumbersOptedOut_773755;
          Action: string = "ListPhoneNumbersOptedOut"; nextToken: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   Action: string (required)
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Version: string (required)
  var query_773770 = newJObject()
  var formData_773771 = newJObject()
  add(query_773770, "Action", newJString(Action))
  add(formData_773771, "nextToken", newJString(nextToken))
  add(query_773770, "Version", newJString(Version))
  result = call_773769.call(nil, query_773770, nil, formData_773771, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_773755(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_773756, base: "/",
    url: url_PostListPhoneNumbersOptedOut_773757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_773739 = ref object of OpenApiRestCall_772597
proc url_GetListPhoneNumbersOptedOut_773741(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListPhoneNumbersOptedOut_773740(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_773742 = query.getOrDefault("nextToken")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "nextToken", valid_773742
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773743 = query.getOrDefault("Action")
  valid_773743 = validateParameter(valid_773743, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_773743 != nil:
    section.add "Action", valid_773743
  var valid_773744 = query.getOrDefault("Version")
  valid_773744 = validateParameter(valid_773744, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773744 != nil:
    section.add "Version", valid_773744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773745 = header.getOrDefault("X-Amz-Date")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Date", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-Security-Token")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Security-Token", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Content-Sha256", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Algorithm")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Algorithm", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Signature")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Signature", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-SignedHeaders", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Credential")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Credential", valid_773751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773752: Call_GetListPhoneNumbersOptedOut_773739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_773752.validator(path, query, header, formData, body)
  let scheme = call_773752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773752.url(scheme.get, call_773752.host, call_773752.base,
                         call_773752.route, valid.getOrDefault("path"))
  result = hook(call_773752, url, valid)

proc call*(call_773753: Call_GetListPhoneNumbersOptedOut_773739;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773754 = newJObject()
  add(query_773754, "nextToken", newJString(nextToken))
  add(query_773754, "Action", newJString(Action))
  add(query_773754, "Version", newJString(Version))
  result = call_773753.call(nil, query_773754, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_773739(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_773740, base: "/",
    url: url_GetListPhoneNumbersOptedOut_773741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_773788 = ref object of OpenApiRestCall_772597
proc url_PostListPlatformApplications_773790(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListPlatformApplications_773789(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773791 = query.getOrDefault("Action")
  valid_773791 = validateParameter(valid_773791, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_773791 != nil:
    section.add "Action", valid_773791
  var valid_773792 = query.getOrDefault("Version")
  valid_773792 = validateParameter(valid_773792, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773792 != nil:
    section.add "Version", valid_773792
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773793 = header.getOrDefault("X-Amz-Date")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-Date", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Security-Token")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Security-Token", valid_773794
  var valid_773795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773795 = validateParameter(valid_773795, JString, required = false,
                                 default = nil)
  if valid_773795 != nil:
    section.add "X-Amz-Content-Sha256", valid_773795
  var valid_773796 = header.getOrDefault("X-Amz-Algorithm")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-Algorithm", valid_773796
  var valid_773797 = header.getOrDefault("X-Amz-Signature")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Signature", valid_773797
  var valid_773798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-SignedHeaders", valid_773798
  var valid_773799 = header.getOrDefault("X-Amz-Credential")
  valid_773799 = validateParameter(valid_773799, JString, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "X-Amz-Credential", valid_773799
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_773800 = formData.getOrDefault("NextToken")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "NextToken", valid_773800
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773801: Call_PostListPlatformApplications_773788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_773801.validator(path, query, header, formData, body)
  let scheme = call_773801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773801.url(scheme.get, call_773801.host, call_773801.base,
                         call_773801.route, valid.getOrDefault("path"))
  result = hook(call_773801, url, valid)

proc call*(call_773802: Call_PostListPlatformApplications_773788;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773803 = newJObject()
  var formData_773804 = newJObject()
  add(formData_773804, "NextToken", newJString(NextToken))
  add(query_773803, "Action", newJString(Action))
  add(query_773803, "Version", newJString(Version))
  result = call_773802.call(nil, query_773803, nil, formData_773804, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_773788(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_773789, base: "/",
    url: url_PostListPlatformApplications_773790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_773772 = ref object of OpenApiRestCall_772597
proc url_GetListPlatformApplications_773774(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListPlatformApplications_773773(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_773775 = query.getOrDefault("NextToken")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "NextToken", valid_773775
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773776 = query.getOrDefault("Action")
  valid_773776 = validateParameter(valid_773776, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_773776 != nil:
    section.add "Action", valid_773776
  var valid_773777 = query.getOrDefault("Version")
  valid_773777 = validateParameter(valid_773777, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773777 != nil:
    section.add "Version", valid_773777
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773778 = header.getOrDefault("X-Amz-Date")
  valid_773778 = validateParameter(valid_773778, JString, required = false,
                                 default = nil)
  if valid_773778 != nil:
    section.add "X-Amz-Date", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Security-Token")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Security-Token", valid_773779
  var valid_773780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773780 = validateParameter(valid_773780, JString, required = false,
                                 default = nil)
  if valid_773780 != nil:
    section.add "X-Amz-Content-Sha256", valid_773780
  var valid_773781 = header.getOrDefault("X-Amz-Algorithm")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-Algorithm", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-Signature")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Signature", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-SignedHeaders", valid_773783
  var valid_773784 = header.getOrDefault("X-Amz-Credential")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "X-Amz-Credential", valid_773784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773785: Call_GetListPlatformApplications_773772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_773785.validator(path, query, header, formData, body)
  let scheme = call_773785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773785.url(scheme.get, call_773785.host, call_773785.base,
                         call_773785.route, valid.getOrDefault("path"))
  result = hook(call_773785, url, valid)

proc call*(call_773786: Call_GetListPlatformApplications_773772;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773787 = newJObject()
  add(query_773787, "NextToken", newJString(NextToken))
  add(query_773787, "Action", newJString(Action))
  add(query_773787, "Version", newJString(Version))
  result = call_773786.call(nil, query_773787, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_773772(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_773773, base: "/",
    url: url_GetListPlatformApplications_773774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_773821 = ref object of OpenApiRestCall_772597
proc url_PostListSubscriptions_773823(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListSubscriptions_773822(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773824 = query.getOrDefault("Action")
  valid_773824 = validateParameter(valid_773824, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_773824 != nil:
    section.add "Action", valid_773824
  var valid_773825 = query.getOrDefault("Version")
  valid_773825 = validateParameter(valid_773825, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773825 != nil:
    section.add "Version", valid_773825
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773826 = header.getOrDefault("X-Amz-Date")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-Date", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-Security-Token")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Security-Token", valid_773827
  var valid_773828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773828 = validateParameter(valid_773828, JString, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "X-Amz-Content-Sha256", valid_773828
  var valid_773829 = header.getOrDefault("X-Amz-Algorithm")
  valid_773829 = validateParameter(valid_773829, JString, required = false,
                                 default = nil)
  if valid_773829 != nil:
    section.add "X-Amz-Algorithm", valid_773829
  var valid_773830 = header.getOrDefault("X-Amz-Signature")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Signature", valid_773830
  var valid_773831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "X-Amz-SignedHeaders", valid_773831
  var valid_773832 = header.getOrDefault("X-Amz-Credential")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Credential", valid_773832
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_773833 = formData.getOrDefault("NextToken")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "NextToken", valid_773833
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773834: Call_PostListSubscriptions_773821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_773834.validator(path, query, header, formData, body)
  let scheme = call_773834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773834.url(scheme.get, call_773834.host, call_773834.base,
                         call_773834.route, valid.getOrDefault("path"))
  result = hook(call_773834, url, valid)

proc call*(call_773835: Call_PostListSubscriptions_773821; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773836 = newJObject()
  var formData_773837 = newJObject()
  add(formData_773837, "NextToken", newJString(NextToken))
  add(query_773836, "Action", newJString(Action))
  add(query_773836, "Version", newJString(Version))
  result = call_773835.call(nil, query_773836, nil, formData_773837, nil)

var postListSubscriptions* = Call_PostListSubscriptions_773821(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_773822, base: "/",
    url: url_PostListSubscriptions_773823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_773805 = ref object of OpenApiRestCall_772597
proc url_GetListSubscriptions_773807(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListSubscriptions_773806(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_773808 = query.getOrDefault("NextToken")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "NextToken", valid_773808
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773809 = query.getOrDefault("Action")
  valid_773809 = validateParameter(valid_773809, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_773809 != nil:
    section.add "Action", valid_773809
  var valid_773810 = query.getOrDefault("Version")
  valid_773810 = validateParameter(valid_773810, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773810 != nil:
    section.add "Version", valid_773810
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773811 = header.getOrDefault("X-Amz-Date")
  valid_773811 = validateParameter(valid_773811, JString, required = false,
                                 default = nil)
  if valid_773811 != nil:
    section.add "X-Amz-Date", valid_773811
  var valid_773812 = header.getOrDefault("X-Amz-Security-Token")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Security-Token", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Content-Sha256", valid_773813
  var valid_773814 = header.getOrDefault("X-Amz-Algorithm")
  valid_773814 = validateParameter(valid_773814, JString, required = false,
                                 default = nil)
  if valid_773814 != nil:
    section.add "X-Amz-Algorithm", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Signature")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Signature", valid_773815
  var valid_773816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-SignedHeaders", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-Credential")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Credential", valid_773817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773818: Call_GetListSubscriptions_773805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_773818.validator(path, query, header, formData, body)
  let scheme = call_773818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773818.url(scheme.get, call_773818.host, call_773818.base,
                         call_773818.route, valid.getOrDefault("path"))
  result = hook(call_773818, url, valid)

proc call*(call_773819: Call_GetListSubscriptions_773805; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773820 = newJObject()
  add(query_773820, "NextToken", newJString(NextToken))
  add(query_773820, "Action", newJString(Action))
  add(query_773820, "Version", newJString(Version))
  result = call_773819.call(nil, query_773820, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_773805(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_773806, base: "/",
    url: url_GetListSubscriptions_773807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_773855 = ref object of OpenApiRestCall_772597
proc url_PostListSubscriptionsByTopic_773857(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListSubscriptionsByTopic_773856(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773858 = query.getOrDefault("Action")
  valid_773858 = validateParameter(valid_773858, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_773858 != nil:
    section.add "Action", valid_773858
  var valid_773859 = query.getOrDefault("Version")
  valid_773859 = validateParameter(valid_773859, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773859 != nil:
    section.add "Version", valid_773859
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773860 = header.getOrDefault("X-Amz-Date")
  valid_773860 = validateParameter(valid_773860, JString, required = false,
                                 default = nil)
  if valid_773860 != nil:
    section.add "X-Amz-Date", valid_773860
  var valid_773861 = header.getOrDefault("X-Amz-Security-Token")
  valid_773861 = validateParameter(valid_773861, JString, required = false,
                                 default = nil)
  if valid_773861 != nil:
    section.add "X-Amz-Security-Token", valid_773861
  var valid_773862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773862 = validateParameter(valid_773862, JString, required = false,
                                 default = nil)
  if valid_773862 != nil:
    section.add "X-Amz-Content-Sha256", valid_773862
  var valid_773863 = header.getOrDefault("X-Amz-Algorithm")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-Algorithm", valid_773863
  var valid_773864 = header.getOrDefault("X-Amz-Signature")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "X-Amz-Signature", valid_773864
  var valid_773865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773865 = validateParameter(valid_773865, JString, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "X-Amz-SignedHeaders", valid_773865
  var valid_773866 = header.getOrDefault("X-Amz-Credential")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-Credential", valid_773866
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_773867 = formData.getOrDefault("NextToken")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "NextToken", valid_773867
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_773868 = formData.getOrDefault("TopicArn")
  valid_773868 = validateParameter(valid_773868, JString, required = true,
                                 default = nil)
  if valid_773868 != nil:
    section.add "TopicArn", valid_773868
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773869: Call_PostListSubscriptionsByTopic_773855; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_773869.validator(path, query, header, formData, body)
  let scheme = call_773869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773869.url(scheme.get, call_773869.host, call_773869.base,
                         call_773869.route, valid.getOrDefault("path"))
  result = hook(call_773869, url, valid)

proc call*(call_773870: Call_PostListSubscriptionsByTopic_773855; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773871 = newJObject()
  var formData_773872 = newJObject()
  add(formData_773872, "NextToken", newJString(NextToken))
  add(formData_773872, "TopicArn", newJString(TopicArn))
  add(query_773871, "Action", newJString(Action))
  add(query_773871, "Version", newJString(Version))
  result = call_773870.call(nil, query_773871, nil, formData_773872, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_773855(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_773856, base: "/",
    url: url_PostListSubscriptionsByTopic_773857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_773838 = ref object of OpenApiRestCall_772597
proc url_GetListSubscriptionsByTopic_773840(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListSubscriptionsByTopic_773839(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Version: JString (required)
  section = newJObject()
  var valid_773841 = query.getOrDefault("NextToken")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "NextToken", valid_773841
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773842 = query.getOrDefault("Action")
  valid_773842 = validateParameter(valid_773842, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_773842 != nil:
    section.add "Action", valid_773842
  var valid_773843 = query.getOrDefault("TopicArn")
  valid_773843 = validateParameter(valid_773843, JString, required = true,
                                 default = nil)
  if valid_773843 != nil:
    section.add "TopicArn", valid_773843
  var valid_773844 = query.getOrDefault("Version")
  valid_773844 = validateParameter(valid_773844, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773844 != nil:
    section.add "Version", valid_773844
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773845 = header.getOrDefault("X-Amz-Date")
  valid_773845 = validateParameter(valid_773845, JString, required = false,
                                 default = nil)
  if valid_773845 != nil:
    section.add "X-Amz-Date", valid_773845
  var valid_773846 = header.getOrDefault("X-Amz-Security-Token")
  valid_773846 = validateParameter(valid_773846, JString, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "X-Amz-Security-Token", valid_773846
  var valid_773847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-Content-Sha256", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-Algorithm")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-Algorithm", valid_773848
  var valid_773849 = header.getOrDefault("X-Amz-Signature")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Signature", valid_773849
  var valid_773850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-SignedHeaders", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-Credential")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Credential", valid_773851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773852: Call_GetListSubscriptionsByTopic_773838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_773852.validator(path, query, header, formData, body)
  let scheme = call_773852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773852.url(scheme.get, call_773852.host, call_773852.base,
                         call_773852.route, valid.getOrDefault("path"))
  result = hook(call_773852, url, valid)

proc call*(call_773853: Call_GetListSubscriptionsByTopic_773838; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Version: string (required)
  var query_773854 = newJObject()
  add(query_773854, "NextToken", newJString(NextToken))
  add(query_773854, "Action", newJString(Action))
  add(query_773854, "TopicArn", newJString(TopicArn))
  add(query_773854, "Version", newJString(Version))
  result = call_773853.call(nil, query_773854, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_773838(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_773839, base: "/",
    url: url_GetListSubscriptionsByTopic_773840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_773889 = ref object of OpenApiRestCall_772597
proc url_PostListTagsForResource_773891(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_773890(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773892 = query.getOrDefault("Action")
  valid_773892 = validateParameter(valid_773892, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_773892 != nil:
    section.add "Action", valid_773892
  var valid_773893 = query.getOrDefault("Version")
  valid_773893 = validateParameter(valid_773893, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773893 != nil:
    section.add "Version", valid_773893
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773894 = header.getOrDefault("X-Amz-Date")
  valid_773894 = validateParameter(valid_773894, JString, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "X-Amz-Date", valid_773894
  var valid_773895 = header.getOrDefault("X-Amz-Security-Token")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Security-Token", valid_773895
  var valid_773896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Content-Sha256", valid_773896
  var valid_773897 = header.getOrDefault("X-Amz-Algorithm")
  valid_773897 = validateParameter(valid_773897, JString, required = false,
                                 default = nil)
  if valid_773897 != nil:
    section.add "X-Amz-Algorithm", valid_773897
  var valid_773898 = header.getOrDefault("X-Amz-Signature")
  valid_773898 = validateParameter(valid_773898, JString, required = false,
                                 default = nil)
  if valid_773898 != nil:
    section.add "X-Amz-Signature", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-SignedHeaders", valid_773899
  var valid_773900 = header.getOrDefault("X-Amz-Credential")
  valid_773900 = validateParameter(valid_773900, JString, required = false,
                                 default = nil)
  if valid_773900 != nil:
    section.add "X-Amz-Credential", valid_773900
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_773901 = formData.getOrDefault("ResourceArn")
  valid_773901 = validateParameter(valid_773901, JString, required = true,
                                 default = nil)
  if valid_773901 != nil:
    section.add "ResourceArn", valid_773901
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773902: Call_PostListTagsForResource_773889; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_773902.validator(path, query, header, formData, body)
  let scheme = call_773902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773902.url(scheme.get, call_773902.host, call_773902.base,
                         call_773902.route, valid.getOrDefault("path"))
  result = hook(call_773902, url, valid)

proc call*(call_773903: Call_PostListTagsForResource_773889; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Version: string (required)
  var query_773904 = newJObject()
  var formData_773905 = newJObject()
  add(query_773904, "Action", newJString(Action))
  add(formData_773905, "ResourceArn", newJString(ResourceArn))
  add(query_773904, "Version", newJString(Version))
  result = call_773903.call(nil, query_773904, nil, formData_773905, nil)

var postListTagsForResource* = Call_PostListTagsForResource_773889(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_773890, base: "/",
    url: url_PostListTagsForResource_773891, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_773873 = ref object of OpenApiRestCall_772597
proc url_GetListTagsForResource_773875(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_773874(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_773876 = query.getOrDefault("ResourceArn")
  valid_773876 = validateParameter(valid_773876, JString, required = true,
                                 default = nil)
  if valid_773876 != nil:
    section.add "ResourceArn", valid_773876
  var valid_773877 = query.getOrDefault("Action")
  valid_773877 = validateParameter(valid_773877, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_773877 != nil:
    section.add "Action", valid_773877
  var valid_773878 = query.getOrDefault("Version")
  valid_773878 = validateParameter(valid_773878, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773878 != nil:
    section.add "Version", valid_773878
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773879 = header.getOrDefault("X-Amz-Date")
  valid_773879 = validateParameter(valid_773879, JString, required = false,
                                 default = nil)
  if valid_773879 != nil:
    section.add "X-Amz-Date", valid_773879
  var valid_773880 = header.getOrDefault("X-Amz-Security-Token")
  valid_773880 = validateParameter(valid_773880, JString, required = false,
                                 default = nil)
  if valid_773880 != nil:
    section.add "X-Amz-Security-Token", valid_773880
  var valid_773881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Content-Sha256", valid_773881
  var valid_773882 = header.getOrDefault("X-Amz-Algorithm")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "X-Amz-Algorithm", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-Signature")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-Signature", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-SignedHeaders", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-Credential")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Credential", valid_773885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773886: Call_GetListTagsForResource_773873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_773886.validator(path, query, header, formData, body)
  let scheme = call_773886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773886.url(scheme.get, call_773886.host, call_773886.base,
                         call_773886.route, valid.getOrDefault("path"))
  result = hook(call_773886, url, valid)

proc call*(call_773887: Call_GetListTagsForResource_773873; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773888 = newJObject()
  add(query_773888, "ResourceArn", newJString(ResourceArn))
  add(query_773888, "Action", newJString(Action))
  add(query_773888, "Version", newJString(Version))
  result = call_773887.call(nil, query_773888, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_773873(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_773874, base: "/",
    url: url_GetListTagsForResource_773875, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_773922 = ref object of OpenApiRestCall_772597
proc url_PostListTopics_773924(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTopics_773923(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773925 = query.getOrDefault("Action")
  valid_773925 = validateParameter(valid_773925, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_773925 != nil:
    section.add "Action", valid_773925
  var valid_773926 = query.getOrDefault("Version")
  valid_773926 = validateParameter(valid_773926, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773926 != nil:
    section.add "Version", valid_773926
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773927 = header.getOrDefault("X-Amz-Date")
  valid_773927 = validateParameter(valid_773927, JString, required = false,
                                 default = nil)
  if valid_773927 != nil:
    section.add "X-Amz-Date", valid_773927
  var valid_773928 = header.getOrDefault("X-Amz-Security-Token")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "X-Amz-Security-Token", valid_773928
  var valid_773929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773929 = validateParameter(valid_773929, JString, required = false,
                                 default = nil)
  if valid_773929 != nil:
    section.add "X-Amz-Content-Sha256", valid_773929
  var valid_773930 = header.getOrDefault("X-Amz-Algorithm")
  valid_773930 = validateParameter(valid_773930, JString, required = false,
                                 default = nil)
  if valid_773930 != nil:
    section.add "X-Amz-Algorithm", valid_773930
  var valid_773931 = header.getOrDefault("X-Amz-Signature")
  valid_773931 = validateParameter(valid_773931, JString, required = false,
                                 default = nil)
  if valid_773931 != nil:
    section.add "X-Amz-Signature", valid_773931
  var valid_773932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773932 = validateParameter(valid_773932, JString, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "X-Amz-SignedHeaders", valid_773932
  var valid_773933 = header.getOrDefault("X-Amz-Credential")
  valid_773933 = validateParameter(valid_773933, JString, required = false,
                                 default = nil)
  if valid_773933 != nil:
    section.add "X-Amz-Credential", valid_773933
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_773934 = formData.getOrDefault("NextToken")
  valid_773934 = validateParameter(valid_773934, JString, required = false,
                                 default = nil)
  if valid_773934 != nil:
    section.add "NextToken", valid_773934
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773935: Call_PostListTopics_773922; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_773935.validator(path, query, header, formData, body)
  let scheme = call_773935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773935.url(scheme.get, call_773935.host, call_773935.base,
                         call_773935.route, valid.getOrDefault("path"))
  result = hook(call_773935, url, valid)

proc call*(call_773936: Call_PostListTopics_773922; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773937 = newJObject()
  var formData_773938 = newJObject()
  add(formData_773938, "NextToken", newJString(NextToken))
  add(query_773937, "Action", newJString(Action))
  add(query_773937, "Version", newJString(Version))
  result = call_773936.call(nil, query_773937, nil, formData_773938, nil)

var postListTopics* = Call_PostListTopics_773922(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_773923,
    base: "/", url: url_PostListTopics_773924, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_773906 = ref object of OpenApiRestCall_772597
proc url_GetListTopics_773908(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTopics_773907(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_773909 = query.getOrDefault("NextToken")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "NextToken", valid_773909
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773910 = query.getOrDefault("Action")
  valid_773910 = validateParameter(valid_773910, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_773910 != nil:
    section.add "Action", valid_773910
  var valid_773911 = query.getOrDefault("Version")
  valid_773911 = validateParameter(valid_773911, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773911 != nil:
    section.add "Version", valid_773911
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773912 = header.getOrDefault("X-Amz-Date")
  valid_773912 = validateParameter(valid_773912, JString, required = false,
                                 default = nil)
  if valid_773912 != nil:
    section.add "X-Amz-Date", valid_773912
  var valid_773913 = header.getOrDefault("X-Amz-Security-Token")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "X-Amz-Security-Token", valid_773913
  var valid_773914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "X-Amz-Content-Sha256", valid_773914
  var valid_773915 = header.getOrDefault("X-Amz-Algorithm")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-Algorithm", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-Signature")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-Signature", valid_773916
  var valid_773917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-SignedHeaders", valid_773917
  var valid_773918 = header.getOrDefault("X-Amz-Credential")
  valid_773918 = validateParameter(valid_773918, JString, required = false,
                                 default = nil)
  if valid_773918 != nil:
    section.add "X-Amz-Credential", valid_773918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773919: Call_GetListTopics_773906; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_773919.validator(path, query, header, formData, body)
  let scheme = call_773919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773919.url(scheme.get, call_773919.host, call_773919.base,
                         call_773919.route, valid.getOrDefault("path"))
  result = hook(call_773919, url, valid)

proc call*(call_773920: Call_GetListTopics_773906; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773921 = newJObject()
  add(query_773921, "NextToken", newJString(NextToken))
  add(query_773921, "Action", newJString(Action))
  add(query_773921, "Version", newJString(Version))
  result = call_773920.call(nil, query_773921, nil, nil, nil)

var getListTopics* = Call_GetListTopics_773906(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_773907,
    base: "/", url: url_GetListTopics_773908, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_773955 = ref object of OpenApiRestCall_772597
proc url_PostOptInPhoneNumber_773957(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostOptInPhoneNumber_773956(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773958 = query.getOrDefault("Action")
  valid_773958 = validateParameter(valid_773958, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_773958 != nil:
    section.add "Action", valid_773958
  var valid_773959 = query.getOrDefault("Version")
  valid_773959 = validateParameter(valid_773959, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773959 != nil:
    section.add "Version", valid_773959
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773960 = header.getOrDefault("X-Amz-Date")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "X-Amz-Date", valid_773960
  var valid_773961 = header.getOrDefault("X-Amz-Security-Token")
  valid_773961 = validateParameter(valid_773961, JString, required = false,
                                 default = nil)
  if valid_773961 != nil:
    section.add "X-Amz-Security-Token", valid_773961
  var valid_773962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773962 = validateParameter(valid_773962, JString, required = false,
                                 default = nil)
  if valid_773962 != nil:
    section.add "X-Amz-Content-Sha256", valid_773962
  var valid_773963 = header.getOrDefault("X-Amz-Algorithm")
  valid_773963 = validateParameter(valid_773963, JString, required = false,
                                 default = nil)
  if valid_773963 != nil:
    section.add "X-Amz-Algorithm", valid_773963
  var valid_773964 = header.getOrDefault("X-Amz-Signature")
  valid_773964 = validateParameter(valid_773964, JString, required = false,
                                 default = nil)
  if valid_773964 != nil:
    section.add "X-Amz-Signature", valid_773964
  var valid_773965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-SignedHeaders", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Credential")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Credential", valid_773966
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_773967 = formData.getOrDefault("phoneNumber")
  valid_773967 = validateParameter(valid_773967, JString, required = true,
                                 default = nil)
  if valid_773967 != nil:
    section.add "phoneNumber", valid_773967
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773968: Call_PostOptInPhoneNumber_773955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_773968.validator(path, query, header, formData, body)
  let scheme = call_773968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773968.url(scheme.get, call_773968.host, call_773968.base,
                         call_773968.route, valid.getOrDefault("path"))
  result = hook(call_773968, url, valid)

proc call*(call_773969: Call_PostOptInPhoneNumber_773955; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Version: string (required)
  var query_773970 = newJObject()
  var formData_773971 = newJObject()
  add(query_773970, "Action", newJString(Action))
  add(formData_773971, "phoneNumber", newJString(phoneNumber))
  add(query_773970, "Version", newJString(Version))
  result = call_773969.call(nil, query_773970, nil, formData_773971, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_773955(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_773956, base: "/",
    url: url_PostOptInPhoneNumber_773957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_773939 = ref object of OpenApiRestCall_772597
proc url_GetOptInPhoneNumber_773941(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOptInPhoneNumber_773940(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `phoneNumber` field"
  var valid_773942 = query.getOrDefault("phoneNumber")
  valid_773942 = validateParameter(valid_773942, JString, required = true,
                                 default = nil)
  if valid_773942 != nil:
    section.add "phoneNumber", valid_773942
  var valid_773943 = query.getOrDefault("Action")
  valid_773943 = validateParameter(valid_773943, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_773943 != nil:
    section.add "Action", valid_773943
  var valid_773944 = query.getOrDefault("Version")
  valid_773944 = validateParameter(valid_773944, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773944 != nil:
    section.add "Version", valid_773944
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773945 = header.getOrDefault("X-Amz-Date")
  valid_773945 = validateParameter(valid_773945, JString, required = false,
                                 default = nil)
  if valid_773945 != nil:
    section.add "X-Amz-Date", valid_773945
  var valid_773946 = header.getOrDefault("X-Amz-Security-Token")
  valid_773946 = validateParameter(valid_773946, JString, required = false,
                                 default = nil)
  if valid_773946 != nil:
    section.add "X-Amz-Security-Token", valid_773946
  var valid_773947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773947 = validateParameter(valid_773947, JString, required = false,
                                 default = nil)
  if valid_773947 != nil:
    section.add "X-Amz-Content-Sha256", valid_773947
  var valid_773948 = header.getOrDefault("X-Amz-Algorithm")
  valid_773948 = validateParameter(valid_773948, JString, required = false,
                                 default = nil)
  if valid_773948 != nil:
    section.add "X-Amz-Algorithm", valid_773948
  var valid_773949 = header.getOrDefault("X-Amz-Signature")
  valid_773949 = validateParameter(valid_773949, JString, required = false,
                                 default = nil)
  if valid_773949 != nil:
    section.add "X-Amz-Signature", valid_773949
  var valid_773950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773950 = validateParameter(valid_773950, JString, required = false,
                                 default = nil)
  if valid_773950 != nil:
    section.add "X-Amz-SignedHeaders", valid_773950
  var valid_773951 = header.getOrDefault("X-Amz-Credential")
  valid_773951 = validateParameter(valid_773951, JString, required = false,
                                 default = nil)
  if valid_773951 != nil:
    section.add "X-Amz-Credential", valid_773951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773952: Call_GetOptInPhoneNumber_773939; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_773952.validator(path, query, header, formData, body)
  let scheme = call_773952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773952.url(scheme.get, call_773952.host, call_773952.base,
                         call_773952.route, valid.getOrDefault("path"))
  result = hook(call_773952, url, valid)

proc call*(call_773953: Call_GetOptInPhoneNumber_773939; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773954 = newJObject()
  add(query_773954, "phoneNumber", newJString(phoneNumber))
  add(query_773954, "Action", newJString(Action))
  add(query_773954, "Version", newJString(Version))
  result = call_773953.call(nil, query_773954, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_773939(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_773940, base: "/",
    url: url_GetOptInPhoneNumber_773941, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_773999 = ref object of OpenApiRestCall_772597
proc url_PostPublish_774001(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPublish_774000(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774002 = query.getOrDefault("Action")
  valid_774002 = validateParameter(valid_774002, JString, required = true,
                                 default = newJString("Publish"))
  if valid_774002 != nil:
    section.add "Action", valid_774002
  var valid_774003 = query.getOrDefault("Version")
  valid_774003 = validateParameter(valid_774003, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774003 != nil:
    section.add "Version", valid_774003
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774004 = header.getOrDefault("X-Amz-Date")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Date", valid_774004
  var valid_774005 = header.getOrDefault("X-Amz-Security-Token")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-Security-Token", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-Content-Sha256", valid_774006
  var valid_774007 = header.getOrDefault("X-Amz-Algorithm")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-Algorithm", valid_774007
  var valid_774008 = header.getOrDefault("X-Amz-Signature")
  valid_774008 = validateParameter(valid_774008, JString, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "X-Amz-Signature", valid_774008
  var valid_774009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774009 = validateParameter(valid_774009, JString, required = false,
                                 default = nil)
  if valid_774009 != nil:
    section.add "X-Amz-SignedHeaders", valid_774009
  var valid_774010 = header.getOrDefault("X-Amz-Credential")
  valid_774010 = validateParameter(valid_774010, JString, required = false,
                                 default = nil)
  if valid_774010 != nil:
    section.add "X-Amz-Credential", valid_774010
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes.1.key: JString
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.1.value: JString
  ##   MessageAttributes.0.key: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.2.key: JString
  ##   MessageAttributes.2.value: JString
  section = newJObject()
  var valid_774011 = formData.getOrDefault("TopicArn")
  valid_774011 = validateParameter(valid_774011, JString, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "TopicArn", valid_774011
  var valid_774012 = formData.getOrDefault("Subject")
  valid_774012 = validateParameter(valid_774012, JString, required = false,
                                 default = nil)
  if valid_774012 != nil:
    section.add "Subject", valid_774012
  var valid_774013 = formData.getOrDefault("MessageAttributes.1.key")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "MessageAttributes.1.key", valid_774013
  var valid_774014 = formData.getOrDefault("TargetArn")
  valid_774014 = validateParameter(valid_774014, JString, required = false,
                                 default = nil)
  if valid_774014 != nil:
    section.add "TargetArn", valid_774014
  var valid_774015 = formData.getOrDefault("PhoneNumber")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "PhoneNumber", valid_774015
  var valid_774016 = formData.getOrDefault("MessageAttributes.0.value")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "MessageAttributes.0.value", valid_774016
  var valid_774017 = formData.getOrDefault("MessageAttributes.1.value")
  valid_774017 = validateParameter(valid_774017, JString, required = false,
                                 default = nil)
  if valid_774017 != nil:
    section.add "MessageAttributes.1.value", valid_774017
  var valid_774018 = formData.getOrDefault("MessageAttributes.0.key")
  valid_774018 = validateParameter(valid_774018, JString, required = false,
                                 default = nil)
  if valid_774018 != nil:
    section.add "MessageAttributes.0.key", valid_774018
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_774019 = formData.getOrDefault("Message")
  valid_774019 = validateParameter(valid_774019, JString, required = true,
                                 default = nil)
  if valid_774019 != nil:
    section.add "Message", valid_774019
  var valid_774020 = formData.getOrDefault("MessageStructure")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "MessageStructure", valid_774020
  var valid_774021 = formData.getOrDefault("MessageAttributes.2.key")
  valid_774021 = validateParameter(valid_774021, JString, required = false,
                                 default = nil)
  if valid_774021 != nil:
    section.add "MessageAttributes.2.key", valid_774021
  var valid_774022 = formData.getOrDefault("MessageAttributes.2.value")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "MessageAttributes.2.value", valid_774022
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774023: Call_PostPublish_773999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_774023.validator(path, query, header, formData, body)
  let scheme = call_774023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774023.url(scheme.get, call_774023.host, call_774023.base,
                         call_774023.route, valid.getOrDefault("path"))
  result = hook(call_774023, url, valid)

proc call*(call_774024: Call_PostPublish_773999; Message: string;
          TopicArn: string = ""; Subject: string = "";
          MessageAttributes1Key: string = ""; TargetArn: string = "";
          PhoneNumber: string = ""; MessageAttributes0Value: string = "";
          MessageAttributes1Value: string = ""; MessageAttributes0Key: string = "";
          Action: string = "Publish"; MessageStructure: string = "";
          MessageAttributes2Key: string = ""; Version: string = "2010-03-31";
          MessageAttributes2Value: string = ""): Recallable =
  ## postPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes1Key: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes1Value: string
  ##   MessageAttributes0Key: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Action: string (required)
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes2Key: string
  ##   Version: string (required)
  ##   MessageAttributes2Value: string
  var query_774025 = newJObject()
  var formData_774026 = newJObject()
  add(formData_774026, "TopicArn", newJString(TopicArn))
  add(formData_774026, "Subject", newJString(Subject))
  add(formData_774026, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_774026, "TargetArn", newJString(TargetArn))
  add(formData_774026, "PhoneNumber", newJString(PhoneNumber))
  add(formData_774026, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_774026, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_774026, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_774026, "Message", newJString(Message))
  add(query_774025, "Action", newJString(Action))
  add(formData_774026, "MessageStructure", newJString(MessageStructure))
  add(formData_774026, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(query_774025, "Version", newJString(Version))
  add(formData_774026, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  result = call_774024.call(nil, query_774025, nil, formData_774026, nil)

var postPublish* = Call_PostPublish_773999(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_774000,
                                        base: "/", url: url_PostPublish_774001,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_773972 = ref object of OpenApiRestCall_772597
proc url_GetPublish_773974(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPublish_773973(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.0.key: JString
  ##   MessageAttributes.1.value: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   Action: JString (required)
  ##   MessageAttributes.2.value: JString
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes.1.key: JString
  ##   MessageAttributes.2.key: JString
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: JString (required)
  section = newJObject()
  var valid_773975 = query.getOrDefault("MessageAttributes.0.value")
  valid_773975 = validateParameter(valid_773975, JString, required = false,
                                 default = nil)
  if valid_773975 != nil:
    section.add "MessageAttributes.0.value", valid_773975
  var valid_773976 = query.getOrDefault("MessageAttributes.0.key")
  valid_773976 = validateParameter(valid_773976, JString, required = false,
                                 default = nil)
  if valid_773976 != nil:
    section.add "MessageAttributes.0.key", valid_773976
  var valid_773977 = query.getOrDefault("MessageAttributes.1.value")
  valid_773977 = validateParameter(valid_773977, JString, required = false,
                                 default = nil)
  if valid_773977 != nil:
    section.add "MessageAttributes.1.value", valid_773977
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_773978 = query.getOrDefault("Message")
  valid_773978 = validateParameter(valid_773978, JString, required = true,
                                 default = nil)
  if valid_773978 != nil:
    section.add "Message", valid_773978
  var valid_773979 = query.getOrDefault("Subject")
  valid_773979 = validateParameter(valid_773979, JString, required = false,
                                 default = nil)
  if valid_773979 != nil:
    section.add "Subject", valid_773979
  var valid_773980 = query.getOrDefault("Action")
  valid_773980 = validateParameter(valid_773980, JString, required = true,
                                 default = newJString("Publish"))
  if valid_773980 != nil:
    section.add "Action", valid_773980
  var valid_773981 = query.getOrDefault("MessageAttributes.2.value")
  valid_773981 = validateParameter(valid_773981, JString, required = false,
                                 default = nil)
  if valid_773981 != nil:
    section.add "MessageAttributes.2.value", valid_773981
  var valid_773982 = query.getOrDefault("MessageStructure")
  valid_773982 = validateParameter(valid_773982, JString, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "MessageStructure", valid_773982
  var valid_773983 = query.getOrDefault("TopicArn")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "TopicArn", valid_773983
  var valid_773984 = query.getOrDefault("PhoneNumber")
  valid_773984 = validateParameter(valid_773984, JString, required = false,
                                 default = nil)
  if valid_773984 != nil:
    section.add "PhoneNumber", valid_773984
  var valid_773985 = query.getOrDefault("MessageAttributes.1.key")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "MessageAttributes.1.key", valid_773985
  var valid_773986 = query.getOrDefault("MessageAttributes.2.key")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "MessageAttributes.2.key", valid_773986
  var valid_773987 = query.getOrDefault("TargetArn")
  valid_773987 = validateParameter(valid_773987, JString, required = false,
                                 default = nil)
  if valid_773987 != nil:
    section.add "TargetArn", valid_773987
  var valid_773988 = query.getOrDefault("Version")
  valid_773988 = validateParameter(valid_773988, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_773988 != nil:
    section.add "Version", valid_773988
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773989 = header.getOrDefault("X-Amz-Date")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "X-Amz-Date", valid_773989
  var valid_773990 = header.getOrDefault("X-Amz-Security-Token")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-Security-Token", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-Content-Sha256", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-Algorithm")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Algorithm", valid_773992
  var valid_773993 = header.getOrDefault("X-Amz-Signature")
  valid_773993 = validateParameter(valid_773993, JString, required = false,
                                 default = nil)
  if valid_773993 != nil:
    section.add "X-Amz-Signature", valid_773993
  var valid_773994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773994 = validateParameter(valid_773994, JString, required = false,
                                 default = nil)
  if valid_773994 != nil:
    section.add "X-Amz-SignedHeaders", valid_773994
  var valid_773995 = header.getOrDefault("X-Amz-Credential")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "X-Amz-Credential", valid_773995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773996: Call_GetPublish_773972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_773996.validator(path, query, header, formData, body)
  let scheme = call_773996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773996.url(scheme.get, call_773996.host, call_773996.base,
                         call_773996.route, valid.getOrDefault("path"))
  result = hook(call_773996, url, valid)

proc call*(call_773997: Call_GetPublish_773972; Message: string;
          MessageAttributes0Value: string = ""; MessageAttributes0Key: string = "";
          MessageAttributes1Value: string = ""; Subject: string = "";
          Action: string = "Publish"; MessageAttributes2Value: string = "";
          MessageStructure: string = ""; TopicArn: string = "";
          PhoneNumber: string = ""; MessageAttributes1Key: string = "";
          MessageAttributes2Key: string = ""; TargetArn: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes0Key: string
  ##   MessageAttributes1Value: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   Action: string (required)
  ##   MessageAttributes2Value: string
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes1Key: string
  ##   MessageAttributes2Key: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: string (required)
  var query_773998 = newJObject()
  add(query_773998, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_773998, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_773998, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_773998, "Message", newJString(Message))
  add(query_773998, "Subject", newJString(Subject))
  add(query_773998, "Action", newJString(Action))
  add(query_773998, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_773998, "MessageStructure", newJString(MessageStructure))
  add(query_773998, "TopicArn", newJString(TopicArn))
  add(query_773998, "PhoneNumber", newJString(PhoneNumber))
  add(query_773998, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_773998, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_773998, "TargetArn", newJString(TargetArn))
  add(query_773998, "Version", newJString(Version))
  result = call_773997.call(nil, query_773998, nil, nil, nil)

var getPublish* = Call_GetPublish_773972(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_773973,
                                      base: "/", url: url_GetPublish_773974,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_774044 = ref object of OpenApiRestCall_772597
proc url_PostRemovePermission_774046(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemovePermission_774045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774047 = query.getOrDefault("Action")
  valid_774047 = validateParameter(valid_774047, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_774047 != nil:
    section.add "Action", valid_774047
  var valid_774048 = query.getOrDefault("Version")
  valid_774048 = validateParameter(valid_774048, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774048 != nil:
    section.add "Version", valid_774048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774049 = header.getOrDefault("X-Amz-Date")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "X-Amz-Date", valid_774049
  var valid_774050 = header.getOrDefault("X-Amz-Security-Token")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = nil)
  if valid_774050 != nil:
    section.add "X-Amz-Security-Token", valid_774050
  var valid_774051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "X-Amz-Content-Sha256", valid_774051
  var valid_774052 = header.getOrDefault("X-Amz-Algorithm")
  valid_774052 = validateParameter(valid_774052, JString, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "X-Amz-Algorithm", valid_774052
  var valid_774053 = header.getOrDefault("X-Amz-Signature")
  valid_774053 = validateParameter(valid_774053, JString, required = false,
                                 default = nil)
  if valid_774053 != nil:
    section.add "X-Amz-Signature", valid_774053
  var valid_774054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774054 = validateParameter(valid_774054, JString, required = false,
                                 default = nil)
  if valid_774054 != nil:
    section.add "X-Amz-SignedHeaders", valid_774054
  var valid_774055 = header.getOrDefault("X-Amz-Credential")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-Credential", valid_774055
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_774056 = formData.getOrDefault("TopicArn")
  valid_774056 = validateParameter(valid_774056, JString, required = true,
                                 default = nil)
  if valid_774056 != nil:
    section.add "TopicArn", valid_774056
  var valid_774057 = formData.getOrDefault("Label")
  valid_774057 = validateParameter(valid_774057, JString, required = true,
                                 default = nil)
  if valid_774057 != nil:
    section.add "Label", valid_774057
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774058: Call_PostRemovePermission_774044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_774058.validator(path, query, header, formData, body)
  let scheme = call_774058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774058.url(scheme.get, call_774058.host, call_774058.base,
                         call_774058.route, valid.getOrDefault("path"))
  result = hook(call_774058, url, valid)

proc call*(call_774059: Call_PostRemovePermission_774044; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## postRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774060 = newJObject()
  var formData_774061 = newJObject()
  add(formData_774061, "TopicArn", newJString(TopicArn))
  add(formData_774061, "Label", newJString(Label))
  add(query_774060, "Action", newJString(Action))
  add(query_774060, "Version", newJString(Version))
  result = call_774059.call(nil, query_774060, nil, formData_774061, nil)

var postRemovePermission* = Call_PostRemovePermission_774044(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_774045, base: "/",
    url: url_PostRemovePermission_774046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_774027 = ref object of OpenApiRestCall_772597
proc url_GetRemovePermission_774029(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemovePermission_774028(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774030 = query.getOrDefault("Action")
  valid_774030 = validateParameter(valid_774030, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_774030 != nil:
    section.add "Action", valid_774030
  var valid_774031 = query.getOrDefault("TopicArn")
  valid_774031 = validateParameter(valid_774031, JString, required = true,
                                 default = nil)
  if valid_774031 != nil:
    section.add "TopicArn", valid_774031
  var valid_774032 = query.getOrDefault("Version")
  valid_774032 = validateParameter(valid_774032, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774032 != nil:
    section.add "Version", valid_774032
  var valid_774033 = query.getOrDefault("Label")
  valid_774033 = validateParameter(valid_774033, JString, required = true,
                                 default = nil)
  if valid_774033 != nil:
    section.add "Label", valid_774033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774034 = header.getOrDefault("X-Amz-Date")
  valid_774034 = validateParameter(valid_774034, JString, required = false,
                                 default = nil)
  if valid_774034 != nil:
    section.add "X-Amz-Date", valid_774034
  var valid_774035 = header.getOrDefault("X-Amz-Security-Token")
  valid_774035 = validateParameter(valid_774035, JString, required = false,
                                 default = nil)
  if valid_774035 != nil:
    section.add "X-Amz-Security-Token", valid_774035
  var valid_774036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774036 = validateParameter(valid_774036, JString, required = false,
                                 default = nil)
  if valid_774036 != nil:
    section.add "X-Amz-Content-Sha256", valid_774036
  var valid_774037 = header.getOrDefault("X-Amz-Algorithm")
  valid_774037 = validateParameter(valid_774037, JString, required = false,
                                 default = nil)
  if valid_774037 != nil:
    section.add "X-Amz-Algorithm", valid_774037
  var valid_774038 = header.getOrDefault("X-Amz-Signature")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "X-Amz-Signature", valid_774038
  var valid_774039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774039 = validateParameter(valid_774039, JString, required = false,
                                 default = nil)
  if valid_774039 != nil:
    section.add "X-Amz-SignedHeaders", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-Credential")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Credential", valid_774040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774041: Call_GetRemovePermission_774027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_774041.validator(path, query, header, formData, body)
  let scheme = call_774041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774041.url(scheme.get, call_774041.host, call_774041.base,
                         call_774041.route, valid.getOrDefault("path"))
  result = hook(call_774041, url, valid)

proc call*(call_774042: Call_GetRemovePermission_774027; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## getRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  var query_774043 = newJObject()
  add(query_774043, "Action", newJString(Action))
  add(query_774043, "TopicArn", newJString(TopicArn))
  add(query_774043, "Version", newJString(Version))
  add(query_774043, "Label", newJString(Label))
  result = call_774042.call(nil, query_774043, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_774027(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_774028, base: "/",
    url: url_GetRemovePermission_774029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_774084 = ref object of OpenApiRestCall_772597
proc url_PostSetEndpointAttributes_774086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetEndpointAttributes_774085(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774087 = query.getOrDefault("Action")
  valid_774087 = validateParameter(valid_774087, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_774087 != nil:
    section.add "Action", valid_774087
  var valid_774088 = query.getOrDefault("Version")
  valid_774088 = validateParameter(valid_774088, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774088 != nil:
    section.add "Version", valid_774088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774089 = header.getOrDefault("X-Amz-Date")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "X-Amz-Date", valid_774089
  var valid_774090 = header.getOrDefault("X-Amz-Security-Token")
  valid_774090 = validateParameter(valid_774090, JString, required = false,
                                 default = nil)
  if valid_774090 != nil:
    section.add "X-Amz-Security-Token", valid_774090
  var valid_774091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774091 = validateParameter(valid_774091, JString, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "X-Amz-Content-Sha256", valid_774091
  var valid_774092 = header.getOrDefault("X-Amz-Algorithm")
  valid_774092 = validateParameter(valid_774092, JString, required = false,
                                 default = nil)
  if valid_774092 != nil:
    section.add "X-Amz-Algorithm", valid_774092
  var valid_774093 = header.getOrDefault("X-Amz-Signature")
  valid_774093 = validateParameter(valid_774093, JString, required = false,
                                 default = nil)
  if valid_774093 != nil:
    section.add "X-Amz-Signature", valid_774093
  var valid_774094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774094 = validateParameter(valid_774094, JString, required = false,
                                 default = nil)
  if valid_774094 != nil:
    section.add "X-Amz-SignedHeaders", valid_774094
  var valid_774095 = header.getOrDefault("X-Amz-Credential")
  valid_774095 = validateParameter(valid_774095, JString, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "X-Amz-Credential", valid_774095
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_774096 = formData.getOrDefault("Attributes.0.value")
  valid_774096 = validateParameter(valid_774096, JString, required = false,
                                 default = nil)
  if valid_774096 != nil:
    section.add "Attributes.0.value", valid_774096
  var valid_774097 = formData.getOrDefault("Attributes.0.key")
  valid_774097 = validateParameter(valid_774097, JString, required = false,
                                 default = nil)
  if valid_774097 != nil:
    section.add "Attributes.0.key", valid_774097
  var valid_774098 = formData.getOrDefault("Attributes.1.key")
  valid_774098 = validateParameter(valid_774098, JString, required = false,
                                 default = nil)
  if valid_774098 != nil:
    section.add "Attributes.1.key", valid_774098
  var valid_774099 = formData.getOrDefault("Attributes.2.value")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "Attributes.2.value", valid_774099
  var valid_774100 = formData.getOrDefault("Attributes.2.key")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "Attributes.2.key", valid_774100
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_774101 = formData.getOrDefault("EndpointArn")
  valid_774101 = validateParameter(valid_774101, JString, required = true,
                                 default = nil)
  if valid_774101 != nil:
    section.add "EndpointArn", valid_774101
  var valid_774102 = formData.getOrDefault("Attributes.1.value")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "Attributes.1.value", valid_774102
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774103: Call_PostSetEndpointAttributes_774084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_774103.validator(path, query, header, formData, body)
  let scheme = call_774103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774103.url(scheme.get, call_774103.host, call_774103.base,
                         call_774103.route, valid.getOrDefault("path"))
  result = hook(call_774103, url, valid)

proc call*(call_774104: Call_PostSetEndpointAttributes_774084; EndpointArn: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes1Key: string = ""; Action: string = "SetEndpointAttributes";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_774105 = newJObject()
  var formData_774106 = newJObject()
  add(formData_774106, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_774106, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_774106, "Attributes.1.key", newJString(Attributes1Key))
  add(query_774105, "Action", newJString(Action))
  add(formData_774106, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_774106, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_774106, "EndpointArn", newJString(EndpointArn))
  add(query_774105, "Version", newJString(Version))
  add(formData_774106, "Attributes.1.value", newJString(Attributes1Value))
  result = call_774104.call(nil, query_774105, nil, formData_774106, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_774084(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_774085, base: "/",
    url: url_PostSetEndpointAttributes_774086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_774062 = ref object of OpenApiRestCall_772597
proc url_GetSetEndpointAttributes_774064(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetEndpointAttributes_774063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EndpointArn` field"
  var valid_774065 = query.getOrDefault("EndpointArn")
  valid_774065 = validateParameter(valid_774065, JString, required = true,
                                 default = nil)
  if valid_774065 != nil:
    section.add "EndpointArn", valid_774065
  var valid_774066 = query.getOrDefault("Attributes.2.key")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "Attributes.2.key", valid_774066
  var valid_774067 = query.getOrDefault("Attributes.1.value")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "Attributes.1.value", valid_774067
  var valid_774068 = query.getOrDefault("Attributes.0.value")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "Attributes.0.value", valid_774068
  var valid_774069 = query.getOrDefault("Action")
  valid_774069 = validateParameter(valid_774069, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_774069 != nil:
    section.add "Action", valid_774069
  var valid_774070 = query.getOrDefault("Attributes.1.key")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "Attributes.1.key", valid_774070
  var valid_774071 = query.getOrDefault("Attributes.2.value")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "Attributes.2.value", valid_774071
  var valid_774072 = query.getOrDefault("Attributes.0.key")
  valid_774072 = validateParameter(valid_774072, JString, required = false,
                                 default = nil)
  if valid_774072 != nil:
    section.add "Attributes.0.key", valid_774072
  var valid_774073 = query.getOrDefault("Version")
  valid_774073 = validateParameter(valid_774073, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774073 != nil:
    section.add "Version", valid_774073
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774074 = header.getOrDefault("X-Amz-Date")
  valid_774074 = validateParameter(valid_774074, JString, required = false,
                                 default = nil)
  if valid_774074 != nil:
    section.add "X-Amz-Date", valid_774074
  var valid_774075 = header.getOrDefault("X-Amz-Security-Token")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "X-Amz-Security-Token", valid_774075
  var valid_774076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "X-Amz-Content-Sha256", valid_774076
  var valid_774077 = header.getOrDefault("X-Amz-Algorithm")
  valid_774077 = validateParameter(valid_774077, JString, required = false,
                                 default = nil)
  if valid_774077 != nil:
    section.add "X-Amz-Algorithm", valid_774077
  var valid_774078 = header.getOrDefault("X-Amz-Signature")
  valid_774078 = validateParameter(valid_774078, JString, required = false,
                                 default = nil)
  if valid_774078 != nil:
    section.add "X-Amz-Signature", valid_774078
  var valid_774079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-SignedHeaders", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Credential")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Credential", valid_774080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774081: Call_GetSetEndpointAttributes_774062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_774081.validator(path, query, header, formData, body)
  let scheme = call_774081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774081.url(scheme.get, call_774081.host, call_774081.base,
                         call_774081.route, valid.getOrDefault("path"))
  result = hook(call_774081, url, valid)

proc call*(call_774082: Call_GetSetEndpointAttributes_774062; EndpointArn: string;
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Attributes0Value: string = ""; Action: string = "SetEndpointAttributes";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes2Key: string
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_774083 = newJObject()
  add(query_774083, "EndpointArn", newJString(EndpointArn))
  add(query_774083, "Attributes.2.key", newJString(Attributes2Key))
  add(query_774083, "Attributes.1.value", newJString(Attributes1Value))
  add(query_774083, "Attributes.0.value", newJString(Attributes0Value))
  add(query_774083, "Action", newJString(Action))
  add(query_774083, "Attributes.1.key", newJString(Attributes1Key))
  add(query_774083, "Attributes.2.value", newJString(Attributes2Value))
  add(query_774083, "Attributes.0.key", newJString(Attributes0Key))
  add(query_774083, "Version", newJString(Version))
  result = call_774082.call(nil, query_774083, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_774062(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_774063, base: "/",
    url: url_GetSetEndpointAttributes_774064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_774129 = ref object of OpenApiRestCall_772597
proc url_PostSetPlatformApplicationAttributes_774131(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetPlatformApplicationAttributes_774130(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774132 = query.getOrDefault("Action")
  valid_774132 = validateParameter(valid_774132, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_774132 != nil:
    section.add "Action", valid_774132
  var valid_774133 = query.getOrDefault("Version")
  valid_774133 = validateParameter(valid_774133, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774133 != nil:
    section.add "Version", valid_774133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774134 = header.getOrDefault("X-Amz-Date")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "X-Amz-Date", valid_774134
  var valid_774135 = header.getOrDefault("X-Amz-Security-Token")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-Security-Token", valid_774135
  var valid_774136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-Content-Sha256", valid_774136
  var valid_774137 = header.getOrDefault("X-Amz-Algorithm")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "X-Amz-Algorithm", valid_774137
  var valid_774138 = header.getOrDefault("X-Amz-Signature")
  valid_774138 = validateParameter(valid_774138, JString, required = false,
                                 default = nil)
  if valid_774138 != nil:
    section.add "X-Amz-Signature", valid_774138
  var valid_774139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774139 = validateParameter(valid_774139, JString, required = false,
                                 default = nil)
  if valid_774139 != nil:
    section.add "X-Amz-SignedHeaders", valid_774139
  var valid_774140 = header.getOrDefault("X-Amz-Credential")
  valid_774140 = validateParameter(valid_774140, JString, required = false,
                                 default = nil)
  if valid_774140 != nil:
    section.add "X-Amz-Credential", valid_774140
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_774141 = formData.getOrDefault("Attributes.0.value")
  valid_774141 = validateParameter(valid_774141, JString, required = false,
                                 default = nil)
  if valid_774141 != nil:
    section.add "Attributes.0.value", valid_774141
  var valid_774142 = formData.getOrDefault("Attributes.0.key")
  valid_774142 = validateParameter(valid_774142, JString, required = false,
                                 default = nil)
  if valid_774142 != nil:
    section.add "Attributes.0.key", valid_774142
  var valid_774143 = formData.getOrDefault("Attributes.1.key")
  valid_774143 = validateParameter(valid_774143, JString, required = false,
                                 default = nil)
  if valid_774143 != nil:
    section.add "Attributes.1.key", valid_774143
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_774144 = formData.getOrDefault("PlatformApplicationArn")
  valid_774144 = validateParameter(valid_774144, JString, required = true,
                                 default = nil)
  if valid_774144 != nil:
    section.add "PlatformApplicationArn", valid_774144
  var valid_774145 = formData.getOrDefault("Attributes.2.value")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "Attributes.2.value", valid_774145
  var valid_774146 = formData.getOrDefault("Attributes.2.key")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "Attributes.2.key", valid_774146
  var valid_774147 = formData.getOrDefault("Attributes.1.value")
  valid_774147 = validateParameter(valid_774147, JString, required = false,
                                 default = nil)
  if valid_774147 != nil:
    section.add "Attributes.1.value", valid_774147
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774148: Call_PostSetPlatformApplicationAttributes_774129;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_774148.validator(path, query, header, formData, body)
  let scheme = call_774148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774148.url(scheme.get, call_774148.host, call_774148.base,
                         call_774148.route, valid.getOrDefault("path"))
  result = hook(call_774148, url, valid)

proc call*(call_774149: Call_PostSetPlatformApplicationAttributes_774129;
          PlatformApplicationArn: string; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_774150 = newJObject()
  var formData_774151 = newJObject()
  add(formData_774151, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_774151, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_774151, "Attributes.1.key", newJString(Attributes1Key))
  add(query_774150, "Action", newJString(Action))
  add(formData_774151, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_774151, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_774151, "Attributes.2.key", newJString(Attributes2Key))
  add(query_774150, "Version", newJString(Version))
  add(formData_774151, "Attributes.1.value", newJString(Attributes1Value))
  result = call_774149.call(nil, query_774150, nil, formData_774151, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_774129(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_774130, base: "/",
    url: url_PostSetPlatformApplicationAttributes_774131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_774107 = ref object of OpenApiRestCall_772597
proc url_GetSetPlatformApplicationAttributes_774109(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetPlatformApplicationAttributes_774108(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  section = newJObject()
  var valid_774110 = query.getOrDefault("Attributes.2.key")
  valid_774110 = validateParameter(valid_774110, JString, required = false,
                                 default = nil)
  if valid_774110 != nil:
    section.add "Attributes.2.key", valid_774110
  var valid_774111 = query.getOrDefault("Attributes.1.value")
  valid_774111 = validateParameter(valid_774111, JString, required = false,
                                 default = nil)
  if valid_774111 != nil:
    section.add "Attributes.1.value", valid_774111
  var valid_774112 = query.getOrDefault("Attributes.0.value")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "Attributes.0.value", valid_774112
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774113 = query.getOrDefault("Action")
  valid_774113 = validateParameter(valid_774113, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_774113 != nil:
    section.add "Action", valid_774113
  var valid_774114 = query.getOrDefault("Attributes.1.key")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "Attributes.1.key", valid_774114
  var valid_774115 = query.getOrDefault("Attributes.2.value")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "Attributes.2.value", valid_774115
  var valid_774116 = query.getOrDefault("Attributes.0.key")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "Attributes.0.key", valid_774116
  var valid_774117 = query.getOrDefault("Version")
  valid_774117 = validateParameter(valid_774117, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774117 != nil:
    section.add "Version", valid_774117
  var valid_774118 = query.getOrDefault("PlatformApplicationArn")
  valid_774118 = validateParameter(valid_774118, JString, required = true,
                                 default = nil)
  if valid_774118 != nil:
    section.add "PlatformApplicationArn", valid_774118
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774119 = header.getOrDefault("X-Amz-Date")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Date", valid_774119
  var valid_774120 = header.getOrDefault("X-Amz-Security-Token")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-Security-Token", valid_774120
  var valid_774121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-Content-Sha256", valid_774121
  var valid_774122 = header.getOrDefault("X-Amz-Algorithm")
  valid_774122 = validateParameter(valid_774122, JString, required = false,
                                 default = nil)
  if valid_774122 != nil:
    section.add "X-Amz-Algorithm", valid_774122
  var valid_774123 = header.getOrDefault("X-Amz-Signature")
  valid_774123 = validateParameter(valid_774123, JString, required = false,
                                 default = nil)
  if valid_774123 != nil:
    section.add "X-Amz-Signature", valid_774123
  var valid_774124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774124 = validateParameter(valid_774124, JString, required = false,
                                 default = nil)
  if valid_774124 != nil:
    section.add "X-Amz-SignedHeaders", valid_774124
  var valid_774125 = header.getOrDefault("X-Amz-Credential")
  valid_774125 = validateParameter(valid_774125, JString, required = false,
                                 default = nil)
  if valid_774125 != nil:
    section.add "X-Amz-Credential", valid_774125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774126: Call_GetSetPlatformApplicationAttributes_774107;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_774126.validator(path, query, header, formData, body)
  let scheme = call_774126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774126.url(scheme.get, call_774126.host, call_774126.base,
                         call_774126.route, valid.getOrDefault("path"))
  result = hook(call_774126, url, valid)

proc call*(call_774127: Call_GetSetPlatformApplicationAttributes_774107;
          PlatformApplicationArn: string; Attributes2Key: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   Attributes2Key: string
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  var query_774128 = newJObject()
  add(query_774128, "Attributes.2.key", newJString(Attributes2Key))
  add(query_774128, "Attributes.1.value", newJString(Attributes1Value))
  add(query_774128, "Attributes.0.value", newJString(Attributes0Value))
  add(query_774128, "Action", newJString(Action))
  add(query_774128, "Attributes.1.key", newJString(Attributes1Key))
  add(query_774128, "Attributes.2.value", newJString(Attributes2Value))
  add(query_774128, "Attributes.0.key", newJString(Attributes0Key))
  add(query_774128, "Version", newJString(Version))
  add(query_774128, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_774127.call(nil, query_774128, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_774107(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_774108, base: "/",
    url: url_GetSetPlatformApplicationAttributes_774109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_774173 = ref object of OpenApiRestCall_772597
proc url_PostSetSMSAttributes_774175(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSMSAttributes_774174(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774176 = query.getOrDefault("Action")
  valid_774176 = validateParameter(valid_774176, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_774176 != nil:
    section.add "Action", valid_774176
  var valid_774177 = query.getOrDefault("Version")
  valid_774177 = validateParameter(valid_774177, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774177 != nil:
    section.add "Version", valid_774177
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774178 = header.getOrDefault("X-Amz-Date")
  valid_774178 = validateParameter(valid_774178, JString, required = false,
                                 default = nil)
  if valid_774178 != nil:
    section.add "X-Amz-Date", valid_774178
  var valid_774179 = header.getOrDefault("X-Amz-Security-Token")
  valid_774179 = validateParameter(valid_774179, JString, required = false,
                                 default = nil)
  if valid_774179 != nil:
    section.add "X-Amz-Security-Token", valid_774179
  var valid_774180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774180 = validateParameter(valid_774180, JString, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "X-Amz-Content-Sha256", valid_774180
  var valid_774181 = header.getOrDefault("X-Amz-Algorithm")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "X-Amz-Algorithm", valid_774181
  var valid_774182 = header.getOrDefault("X-Amz-Signature")
  valid_774182 = validateParameter(valid_774182, JString, required = false,
                                 default = nil)
  if valid_774182 != nil:
    section.add "X-Amz-Signature", valid_774182
  var valid_774183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774183 = validateParameter(valid_774183, JString, required = false,
                                 default = nil)
  if valid_774183 != nil:
    section.add "X-Amz-SignedHeaders", valid_774183
  var valid_774184 = header.getOrDefault("X-Amz-Credential")
  valid_774184 = validateParameter(valid_774184, JString, required = false,
                                 default = nil)
  if valid_774184 != nil:
    section.add "X-Amz-Credential", valid_774184
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.2.value: JString
  ##   attributes.2.key: JString
  ##   attributes.1.value: JString
  ##   attributes.1.key: JString
  ##   attributes.0.key: JString
  ##   attributes.0.value: JString
  section = newJObject()
  var valid_774185 = formData.getOrDefault("attributes.2.value")
  valid_774185 = validateParameter(valid_774185, JString, required = false,
                                 default = nil)
  if valid_774185 != nil:
    section.add "attributes.2.value", valid_774185
  var valid_774186 = formData.getOrDefault("attributes.2.key")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "attributes.2.key", valid_774186
  var valid_774187 = formData.getOrDefault("attributes.1.value")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "attributes.1.value", valid_774187
  var valid_774188 = formData.getOrDefault("attributes.1.key")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "attributes.1.key", valid_774188
  var valid_774189 = formData.getOrDefault("attributes.0.key")
  valid_774189 = validateParameter(valid_774189, JString, required = false,
                                 default = nil)
  if valid_774189 != nil:
    section.add "attributes.0.key", valid_774189
  var valid_774190 = formData.getOrDefault("attributes.0.value")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "attributes.0.value", valid_774190
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774191: Call_PostSetSMSAttributes_774173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_774191.validator(path, query, header, formData, body)
  let scheme = call_774191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774191.url(scheme.get, call_774191.host, call_774191.base,
                         call_774191.route, valid.getOrDefault("path"))
  result = hook(call_774191, url, valid)

proc call*(call_774192: Call_PostSetSMSAttributes_774173;
          attributes2Value: string = ""; attributes2Key: string = "";
          Action: string = "SetSMSAttributes"; attributes1Value: string = "";
          attributes1Key: string = ""; attributes0Key: string = "";
          Version: string = "2010-03-31"; attributes0Value: string = ""): Recallable =
  ## postSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes2Value: string
  ##   attributes2Key: string
  ##   Action: string (required)
  ##   attributes1Value: string
  ##   attributes1Key: string
  ##   attributes0Key: string
  ##   Version: string (required)
  ##   attributes0Value: string
  var query_774193 = newJObject()
  var formData_774194 = newJObject()
  add(formData_774194, "attributes.2.value", newJString(attributes2Value))
  add(formData_774194, "attributes.2.key", newJString(attributes2Key))
  add(query_774193, "Action", newJString(Action))
  add(formData_774194, "attributes.1.value", newJString(attributes1Value))
  add(formData_774194, "attributes.1.key", newJString(attributes1Key))
  add(formData_774194, "attributes.0.key", newJString(attributes0Key))
  add(query_774193, "Version", newJString(Version))
  add(formData_774194, "attributes.0.value", newJString(attributes0Value))
  result = call_774192.call(nil, query_774193, nil, formData_774194, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_774173(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_774174, base: "/",
    url: url_PostSetSMSAttributes_774175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_774152 = ref object of OpenApiRestCall_772597
proc url_GetSetSMSAttributes_774154(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSMSAttributes_774153(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   attributes.2.key: JString
  ##   attributes.1.key: JString
  ##   Action: JString (required)
  ##   attributes.1.value: JString
  ##   attributes.0.value: JString
  ##   attributes.2.value: JString
  ##   attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_774155 = query.getOrDefault("attributes.2.key")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "attributes.2.key", valid_774155
  var valid_774156 = query.getOrDefault("attributes.1.key")
  valid_774156 = validateParameter(valid_774156, JString, required = false,
                                 default = nil)
  if valid_774156 != nil:
    section.add "attributes.1.key", valid_774156
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774157 = query.getOrDefault("Action")
  valid_774157 = validateParameter(valid_774157, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_774157 != nil:
    section.add "Action", valid_774157
  var valid_774158 = query.getOrDefault("attributes.1.value")
  valid_774158 = validateParameter(valid_774158, JString, required = false,
                                 default = nil)
  if valid_774158 != nil:
    section.add "attributes.1.value", valid_774158
  var valid_774159 = query.getOrDefault("attributes.0.value")
  valid_774159 = validateParameter(valid_774159, JString, required = false,
                                 default = nil)
  if valid_774159 != nil:
    section.add "attributes.0.value", valid_774159
  var valid_774160 = query.getOrDefault("attributes.2.value")
  valid_774160 = validateParameter(valid_774160, JString, required = false,
                                 default = nil)
  if valid_774160 != nil:
    section.add "attributes.2.value", valid_774160
  var valid_774161 = query.getOrDefault("attributes.0.key")
  valid_774161 = validateParameter(valid_774161, JString, required = false,
                                 default = nil)
  if valid_774161 != nil:
    section.add "attributes.0.key", valid_774161
  var valid_774162 = query.getOrDefault("Version")
  valid_774162 = validateParameter(valid_774162, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774162 != nil:
    section.add "Version", valid_774162
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774163 = header.getOrDefault("X-Amz-Date")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "X-Amz-Date", valid_774163
  var valid_774164 = header.getOrDefault("X-Amz-Security-Token")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "X-Amz-Security-Token", valid_774164
  var valid_774165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "X-Amz-Content-Sha256", valid_774165
  var valid_774166 = header.getOrDefault("X-Amz-Algorithm")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-Algorithm", valid_774166
  var valid_774167 = header.getOrDefault("X-Amz-Signature")
  valid_774167 = validateParameter(valid_774167, JString, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "X-Amz-Signature", valid_774167
  var valid_774168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "X-Amz-SignedHeaders", valid_774168
  var valid_774169 = header.getOrDefault("X-Amz-Credential")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "X-Amz-Credential", valid_774169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774170: Call_GetSetSMSAttributes_774152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_774170.validator(path, query, header, formData, body)
  let scheme = call_774170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774170.url(scheme.get, call_774170.host, call_774170.base,
                         call_774170.route, valid.getOrDefault("path"))
  result = hook(call_774170, url, valid)

proc call*(call_774171: Call_GetSetSMSAttributes_774152;
          attributes2Key: string = ""; attributes1Key: string = "";
          Action: string = "SetSMSAttributes"; attributes1Value: string = "";
          attributes0Value: string = ""; attributes2Value: string = "";
          attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes2Key: string
  ##   attributes1Key: string
  ##   Action: string (required)
  ##   attributes1Value: string
  ##   attributes0Value: string
  ##   attributes2Value: string
  ##   attributes0Key: string
  ##   Version: string (required)
  var query_774172 = newJObject()
  add(query_774172, "attributes.2.key", newJString(attributes2Key))
  add(query_774172, "attributes.1.key", newJString(attributes1Key))
  add(query_774172, "Action", newJString(Action))
  add(query_774172, "attributes.1.value", newJString(attributes1Value))
  add(query_774172, "attributes.0.value", newJString(attributes0Value))
  add(query_774172, "attributes.2.value", newJString(attributes2Value))
  add(query_774172, "attributes.0.key", newJString(attributes0Key))
  add(query_774172, "Version", newJString(Version))
  result = call_774171.call(nil, query_774172, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_774152(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_774153, base: "/",
    url: url_GetSetSMSAttributes_774154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_774213 = ref object of OpenApiRestCall_772597
proc url_PostSetSubscriptionAttributes_774215(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSubscriptionAttributes_774214(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774216 = query.getOrDefault("Action")
  valid_774216 = validateParameter(valid_774216, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_774216 != nil:
    section.add "Action", valid_774216
  var valid_774217 = query.getOrDefault("Version")
  valid_774217 = validateParameter(valid_774217, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774217 != nil:
    section.add "Version", valid_774217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774218 = header.getOrDefault("X-Amz-Date")
  valid_774218 = validateParameter(valid_774218, JString, required = false,
                                 default = nil)
  if valid_774218 != nil:
    section.add "X-Amz-Date", valid_774218
  var valid_774219 = header.getOrDefault("X-Amz-Security-Token")
  valid_774219 = validateParameter(valid_774219, JString, required = false,
                                 default = nil)
  if valid_774219 != nil:
    section.add "X-Amz-Security-Token", valid_774219
  var valid_774220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774220 = validateParameter(valid_774220, JString, required = false,
                                 default = nil)
  if valid_774220 != nil:
    section.add "X-Amz-Content-Sha256", valid_774220
  var valid_774221 = header.getOrDefault("X-Amz-Algorithm")
  valid_774221 = validateParameter(valid_774221, JString, required = false,
                                 default = nil)
  if valid_774221 != nil:
    section.add "X-Amz-Algorithm", valid_774221
  var valid_774222 = header.getOrDefault("X-Amz-Signature")
  valid_774222 = validateParameter(valid_774222, JString, required = false,
                                 default = nil)
  if valid_774222 != nil:
    section.add "X-Amz-Signature", valid_774222
  var valid_774223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774223 = validateParameter(valid_774223, JString, required = false,
                                 default = nil)
  if valid_774223 != nil:
    section.add "X-Amz-SignedHeaders", valid_774223
  var valid_774224 = header.getOrDefault("X-Amz-Credential")
  valid_774224 = validateParameter(valid_774224, JString, required = false,
                                 default = nil)
  if valid_774224 != nil:
    section.add "X-Amz-Credential", valid_774224
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_774225 = formData.getOrDefault("AttributeName")
  valid_774225 = validateParameter(valid_774225, JString, required = true,
                                 default = nil)
  if valid_774225 != nil:
    section.add "AttributeName", valid_774225
  var valid_774226 = formData.getOrDefault("AttributeValue")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "AttributeValue", valid_774226
  var valid_774227 = formData.getOrDefault("SubscriptionArn")
  valid_774227 = validateParameter(valid_774227, JString, required = true,
                                 default = nil)
  if valid_774227 != nil:
    section.add "SubscriptionArn", valid_774227
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774228: Call_PostSetSubscriptionAttributes_774213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_774228.validator(path, query, header, formData, body)
  let scheme = call_774228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774228.url(scheme.get, call_774228.host, call_774228.base,
                         call_774228.route, valid.getOrDefault("path"))
  result = hook(call_774228, url, valid)

proc call*(call_774229: Call_PostSetSubscriptionAttributes_774213;
          AttributeName: string; SubscriptionArn: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   Version: string (required)
  var query_774230 = newJObject()
  var formData_774231 = newJObject()
  add(formData_774231, "AttributeName", newJString(AttributeName))
  add(formData_774231, "AttributeValue", newJString(AttributeValue))
  add(query_774230, "Action", newJString(Action))
  add(formData_774231, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_774230, "Version", newJString(Version))
  result = call_774229.call(nil, query_774230, nil, formData_774231, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_774213(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_774214, base: "/",
    url: url_PostSetSubscriptionAttributes_774215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_774195 = ref object of OpenApiRestCall_772597
proc url_GetSetSubscriptionAttributes_774197(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSubscriptionAttributes_774196(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   Action: JString (required)
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_774198 = query.getOrDefault("SubscriptionArn")
  valid_774198 = validateParameter(valid_774198, JString, required = true,
                                 default = nil)
  if valid_774198 != nil:
    section.add "SubscriptionArn", valid_774198
  var valid_774199 = query.getOrDefault("AttributeName")
  valid_774199 = validateParameter(valid_774199, JString, required = true,
                                 default = nil)
  if valid_774199 != nil:
    section.add "AttributeName", valid_774199
  var valid_774200 = query.getOrDefault("Action")
  valid_774200 = validateParameter(valid_774200, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_774200 != nil:
    section.add "Action", valid_774200
  var valid_774201 = query.getOrDefault("AttributeValue")
  valid_774201 = validateParameter(valid_774201, JString, required = false,
                                 default = nil)
  if valid_774201 != nil:
    section.add "AttributeValue", valid_774201
  var valid_774202 = query.getOrDefault("Version")
  valid_774202 = validateParameter(valid_774202, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774202 != nil:
    section.add "Version", valid_774202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774203 = header.getOrDefault("X-Amz-Date")
  valid_774203 = validateParameter(valid_774203, JString, required = false,
                                 default = nil)
  if valid_774203 != nil:
    section.add "X-Amz-Date", valid_774203
  var valid_774204 = header.getOrDefault("X-Amz-Security-Token")
  valid_774204 = validateParameter(valid_774204, JString, required = false,
                                 default = nil)
  if valid_774204 != nil:
    section.add "X-Amz-Security-Token", valid_774204
  var valid_774205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774205 = validateParameter(valid_774205, JString, required = false,
                                 default = nil)
  if valid_774205 != nil:
    section.add "X-Amz-Content-Sha256", valid_774205
  var valid_774206 = header.getOrDefault("X-Amz-Algorithm")
  valid_774206 = validateParameter(valid_774206, JString, required = false,
                                 default = nil)
  if valid_774206 != nil:
    section.add "X-Amz-Algorithm", valid_774206
  var valid_774207 = header.getOrDefault("X-Amz-Signature")
  valid_774207 = validateParameter(valid_774207, JString, required = false,
                                 default = nil)
  if valid_774207 != nil:
    section.add "X-Amz-Signature", valid_774207
  var valid_774208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "X-Amz-SignedHeaders", valid_774208
  var valid_774209 = header.getOrDefault("X-Amz-Credential")
  valid_774209 = validateParameter(valid_774209, JString, required = false,
                                 default = nil)
  if valid_774209 != nil:
    section.add "X-Amz-Credential", valid_774209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774210: Call_GetSetSubscriptionAttributes_774195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_774210.validator(path, query, header, formData, body)
  let scheme = call_774210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774210.url(scheme.get, call_774210.host, call_774210.base,
                         call_774210.route, valid.getOrDefault("path"))
  result = hook(call_774210, url, valid)

proc call*(call_774211: Call_GetSetSubscriptionAttributes_774195;
          SubscriptionArn: string; AttributeName: string;
          Action: string = "SetSubscriptionAttributes"; AttributeValue: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   Action: string (required)
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Version: string (required)
  var query_774212 = newJObject()
  add(query_774212, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_774212, "AttributeName", newJString(AttributeName))
  add(query_774212, "Action", newJString(Action))
  add(query_774212, "AttributeValue", newJString(AttributeValue))
  add(query_774212, "Version", newJString(Version))
  result = call_774211.call(nil, query_774212, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_774195(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_774196, base: "/",
    url: url_GetSetSubscriptionAttributes_774197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_774250 = ref object of OpenApiRestCall_772597
proc url_PostSetTopicAttributes_774252(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetTopicAttributes_774251(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774253 = query.getOrDefault("Action")
  valid_774253 = validateParameter(valid_774253, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_774253 != nil:
    section.add "Action", valid_774253
  var valid_774254 = query.getOrDefault("Version")
  valid_774254 = validateParameter(valid_774254, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774254 != nil:
    section.add "Version", valid_774254
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774255 = header.getOrDefault("X-Amz-Date")
  valid_774255 = validateParameter(valid_774255, JString, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "X-Amz-Date", valid_774255
  var valid_774256 = header.getOrDefault("X-Amz-Security-Token")
  valid_774256 = validateParameter(valid_774256, JString, required = false,
                                 default = nil)
  if valid_774256 != nil:
    section.add "X-Amz-Security-Token", valid_774256
  var valid_774257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774257 = validateParameter(valid_774257, JString, required = false,
                                 default = nil)
  if valid_774257 != nil:
    section.add "X-Amz-Content-Sha256", valid_774257
  var valid_774258 = header.getOrDefault("X-Amz-Algorithm")
  valid_774258 = validateParameter(valid_774258, JString, required = false,
                                 default = nil)
  if valid_774258 != nil:
    section.add "X-Amz-Algorithm", valid_774258
  var valid_774259 = header.getOrDefault("X-Amz-Signature")
  valid_774259 = validateParameter(valid_774259, JString, required = false,
                                 default = nil)
  if valid_774259 != nil:
    section.add "X-Amz-Signature", valid_774259
  var valid_774260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774260 = validateParameter(valid_774260, JString, required = false,
                                 default = nil)
  if valid_774260 != nil:
    section.add "X-Amz-SignedHeaders", valid_774260
  var valid_774261 = header.getOrDefault("X-Amz-Credential")
  valid_774261 = validateParameter(valid_774261, JString, required = false,
                                 default = nil)
  if valid_774261 != nil:
    section.add "X-Amz-Credential", valid_774261
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_774262 = formData.getOrDefault("TopicArn")
  valid_774262 = validateParameter(valid_774262, JString, required = true,
                                 default = nil)
  if valid_774262 != nil:
    section.add "TopicArn", valid_774262
  var valid_774263 = formData.getOrDefault("AttributeName")
  valid_774263 = validateParameter(valid_774263, JString, required = true,
                                 default = nil)
  if valid_774263 != nil:
    section.add "AttributeName", valid_774263
  var valid_774264 = formData.getOrDefault("AttributeValue")
  valid_774264 = validateParameter(valid_774264, JString, required = false,
                                 default = nil)
  if valid_774264 != nil:
    section.add "AttributeValue", valid_774264
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774265: Call_PostSetTopicAttributes_774250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_774265.validator(path, query, header, formData, body)
  let scheme = call_774265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774265.url(scheme.get, call_774265.host, call_774265.base,
                         call_774265.route, valid.getOrDefault("path"))
  result = hook(call_774265, url, valid)

proc call*(call_774266: Call_PostSetTopicAttributes_774250; TopicArn: string;
          AttributeName: string; AttributeValue: string = "";
          Action: string = "SetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774267 = newJObject()
  var formData_774268 = newJObject()
  add(formData_774268, "TopicArn", newJString(TopicArn))
  add(formData_774268, "AttributeName", newJString(AttributeName))
  add(formData_774268, "AttributeValue", newJString(AttributeValue))
  add(query_774267, "Action", newJString(Action))
  add(query_774267, "Version", newJString(Version))
  result = call_774266.call(nil, query_774267, nil, formData_774268, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_774250(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_774251, base: "/",
    url: url_PostSetTopicAttributes_774252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_774232 = ref object of OpenApiRestCall_772597
proc url_GetSetTopicAttributes_774234(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetTopicAttributes_774233(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Action: JString (required)
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AttributeName` field"
  var valid_774235 = query.getOrDefault("AttributeName")
  valid_774235 = validateParameter(valid_774235, JString, required = true,
                                 default = nil)
  if valid_774235 != nil:
    section.add "AttributeName", valid_774235
  var valid_774236 = query.getOrDefault("Action")
  valid_774236 = validateParameter(valid_774236, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_774236 != nil:
    section.add "Action", valid_774236
  var valid_774237 = query.getOrDefault("AttributeValue")
  valid_774237 = validateParameter(valid_774237, JString, required = false,
                                 default = nil)
  if valid_774237 != nil:
    section.add "AttributeValue", valid_774237
  var valid_774238 = query.getOrDefault("TopicArn")
  valid_774238 = validateParameter(valid_774238, JString, required = true,
                                 default = nil)
  if valid_774238 != nil:
    section.add "TopicArn", valid_774238
  var valid_774239 = query.getOrDefault("Version")
  valid_774239 = validateParameter(valid_774239, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774239 != nil:
    section.add "Version", valid_774239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774240 = header.getOrDefault("X-Amz-Date")
  valid_774240 = validateParameter(valid_774240, JString, required = false,
                                 default = nil)
  if valid_774240 != nil:
    section.add "X-Amz-Date", valid_774240
  var valid_774241 = header.getOrDefault("X-Amz-Security-Token")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "X-Amz-Security-Token", valid_774241
  var valid_774242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774242 = validateParameter(valid_774242, JString, required = false,
                                 default = nil)
  if valid_774242 != nil:
    section.add "X-Amz-Content-Sha256", valid_774242
  var valid_774243 = header.getOrDefault("X-Amz-Algorithm")
  valid_774243 = validateParameter(valid_774243, JString, required = false,
                                 default = nil)
  if valid_774243 != nil:
    section.add "X-Amz-Algorithm", valid_774243
  var valid_774244 = header.getOrDefault("X-Amz-Signature")
  valid_774244 = validateParameter(valid_774244, JString, required = false,
                                 default = nil)
  if valid_774244 != nil:
    section.add "X-Amz-Signature", valid_774244
  var valid_774245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774245 = validateParameter(valid_774245, JString, required = false,
                                 default = nil)
  if valid_774245 != nil:
    section.add "X-Amz-SignedHeaders", valid_774245
  var valid_774246 = header.getOrDefault("X-Amz-Credential")
  valid_774246 = validateParameter(valid_774246, JString, required = false,
                                 default = nil)
  if valid_774246 != nil:
    section.add "X-Amz-Credential", valid_774246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774247: Call_GetSetTopicAttributes_774232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_774247.validator(path, query, header, formData, body)
  let scheme = call_774247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774247.url(scheme.get, call_774247.host, call_774247.base,
                         call_774247.route, valid.getOrDefault("path"))
  result = hook(call_774247, url, valid)

proc call*(call_774248: Call_GetSetTopicAttributes_774232; AttributeName: string;
          TopicArn: string; Action: string = "SetTopicAttributes";
          AttributeValue: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Action: string (required)
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  ##   Version: string (required)
  var query_774249 = newJObject()
  add(query_774249, "AttributeName", newJString(AttributeName))
  add(query_774249, "Action", newJString(Action))
  add(query_774249, "AttributeValue", newJString(AttributeValue))
  add(query_774249, "TopicArn", newJString(TopicArn))
  add(query_774249, "Version", newJString(Version))
  result = call_774248.call(nil, query_774249, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_774232(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_774233, base: "/",
    url: url_GetSetTopicAttributes_774234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_774294 = ref object of OpenApiRestCall_772597
proc url_PostSubscribe_774296(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSubscribe_774295(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774297 = query.getOrDefault("Action")
  valid_774297 = validateParameter(valid_774297, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_774297 != nil:
    section.add "Action", valid_774297
  var valid_774298 = query.getOrDefault("Version")
  valid_774298 = validateParameter(valid_774298, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774298 != nil:
    section.add "Version", valid_774298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774299 = header.getOrDefault("X-Amz-Date")
  valid_774299 = validateParameter(valid_774299, JString, required = false,
                                 default = nil)
  if valid_774299 != nil:
    section.add "X-Amz-Date", valid_774299
  var valid_774300 = header.getOrDefault("X-Amz-Security-Token")
  valid_774300 = validateParameter(valid_774300, JString, required = false,
                                 default = nil)
  if valid_774300 != nil:
    section.add "X-Amz-Security-Token", valid_774300
  var valid_774301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774301 = validateParameter(valid_774301, JString, required = false,
                                 default = nil)
  if valid_774301 != nil:
    section.add "X-Amz-Content-Sha256", valid_774301
  var valid_774302 = header.getOrDefault("X-Amz-Algorithm")
  valid_774302 = validateParameter(valid_774302, JString, required = false,
                                 default = nil)
  if valid_774302 != nil:
    section.add "X-Amz-Algorithm", valid_774302
  var valid_774303 = header.getOrDefault("X-Amz-Signature")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "X-Amz-Signature", valid_774303
  var valid_774304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-SignedHeaders", valid_774304
  var valid_774305 = header.getOrDefault("X-Amz-Credential")
  valid_774305 = validateParameter(valid_774305, JString, required = false,
                                 default = nil)
  if valid_774305 != nil:
    section.add "X-Amz-Credential", valid_774305
  result.add "header", section
  ## parameters in `formData` object:
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes.0.value: JString
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_774306 = formData.getOrDefault("Endpoint")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "Endpoint", valid_774306
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_774307 = formData.getOrDefault("TopicArn")
  valid_774307 = validateParameter(valid_774307, JString, required = true,
                                 default = nil)
  if valid_774307 != nil:
    section.add "TopicArn", valid_774307
  var valid_774308 = formData.getOrDefault("Attributes.0.value")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "Attributes.0.value", valid_774308
  var valid_774309 = formData.getOrDefault("Protocol")
  valid_774309 = validateParameter(valid_774309, JString, required = true,
                                 default = nil)
  if valid_774309 != nil:
    section.add "Protocol", valid_774309
  var valid_774310 = formData.getOrDefault("Attributes.0.key")
  valid_774310 = validateParameter(valid_774310, JString, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "Attributes.0.key", valid_774310
  var valid_774311 = formData.getOrDefault("Attributes.1.key")
  valid_774311 = validateParameter(valid_774311, JString, required = false,
                                 default = nil)
  if valid_774311 != nil:
    section.add "Attributes.1.key", valid_774311
  var valid_774312 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_774312 = validateParameter(valid_774312, JBool, required = false, default = nil)
  if valid_774312 != nil:
    section.add "ReturnSubscriptionArn", valid_774312
  var valid_774313 = formData.getOrDefault("Attributes.2.value")
  valid_774313 = validateParameter(valid_774313, JString, required = false,
                                 default = nil)
  if valid_774313 != nil:
    section.add "Attributes.2.value", valid_774313
  var valid_774314 = formData.getOrDefault("Attributes.2.key")
  valid_774314 = validateParameter(valid_774314, JString, required = false,
                                 default = nil)
  if valid_774314 != nil:
    section.add "Attributes.2.key", valid_774314
  var valid_774315 = formData.getOrDefault("Attributes.1.value")
  valid_774315 = validateParameter(valid_774315, JString, required = false,
                                 default = nil)
  if valid_774315 != nil:
    section.add "Attributes.1.value", valid_774315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774316: Call_PostSubscribe_774294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_774316.validator(path, query, header, formData, body)
  let scheme = call_774316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774316.url(scheme.get, call_774316.host, call_774316.base,
                         call_774316.route, valid.getOrDefault("path"))
  result = hook(call_774316, url, valid)

proc call*(call_774317: Call_PostSubscribe_774294; TopicArn: string;
          Protocol: string; Endpoint: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          ReturnSubscriptionArn: bool = false; Action: string = "Subscribe";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes0Value: string
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_774318 = newJObject()
  var formData_774319 = newJObject()
  add(formData_774319, "Endpoint", newJString(Endpoint))
  add(formData_774319, "TopicArn", newJString(TopicArn))
  add(formData_774319, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_774319, "Protocol", newJString(Protocol))
  add(formData_774319, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_774319, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_774319, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_774318, "Action", newJString(Action))
  add(formData_774319, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_774319, "Attributes.2.key", newJString(Attributes2Key))
  add(query_774318, "Version", newJString(Version))
  add(formData_774319, "Attributes.1.value", newJString(Attributes1Value))
  result = call_774317.call(nil, query_774318, nil, formData_774319, nil)

var postSubscribe* = Call_PostSubscribe_774294(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_774295,
    base: "/", url: url_PostSubscribe_774296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_774269 = ref object of OpenApiRestCall_772597
proc url_GetSubscribe_774271(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSubscribe_774270(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.1.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_774272 = query.getOrDefault("Attributes.2.key")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "Attributes.2.key", valid_774272
  var valid_774273 = query.getOrDefault("Endpoint")
  valid_774273 = validateParameter(valid_774273, JString, required = false,
                                 default = nil)
  if valid_774273 != nil:
    section.add "Endpoint", valid_774273
  assert query != nil,
        "query argument is necessary due to required `Protocol` field"
  var valid_774274 = query.getOrDefault("Protocol")
  valid_774274 = validateParameter(valid_774274, JString, required = true,
                                 default = nil)
  if valid_774274 != nil:
    section.add "Protocol", valid_774274
  var valid_774275 = query.getOrDefault("Attributes.1.value")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "Attributes.1.value", valid_774275
  var valid_774276 = query.getOrDefault("Attributes.0.value")
  valid_774276 = validateParameter(valid_774276, JString, required = false,
                                 default = nil)
  if valid_774276 != nil:
    section.add "Attributes.0.value", valid_774276
  var valid_774277 = query.getOrDefault("Action")
  valid_774277 = validateParameter(valid_774277, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_774277 != nil:
    section.add "Action", valid_774277
  var valid_774278 = query.getOrDefault("ReturnSubscriptionArn")
  valid_774278 = validateParameter(valid_774278, JBool, required = false, default = nil)
  if valid_774278 != nil:
    section.add "ReturnSubscriptionArn", valid_774278
  var valid_774279 = query.getOrDefault("Attributes.1.key")
  valid_774279 = validateParameter(valid_774279, JString, required = false,
                                 default = nil)
  if valid_774279 != nil:
    section.add "Attributes.1.key", valid_774279
  var valid_774280 = query.getOrDefault("TopicArn")
  valid_774280 = validateParameter(valid_774280, JString, required = true,
                                 default = nil)
  if valid_774280 != nil:
    section.add "TopicArn", valid_774280
  var valid_774281 = query.getOrDefault("Attributes.2.value")
  valid_774281 = validateParameter(valid_774281, JString, required = false,
                                 default = nil)
  if valid_774281 != nil:
    section.add "Attributes.2.value", valid_774281
  var valid_774282 = query.getOrDefault("Attributes.0.key")
  valid_774282 = validateParameter(valid_774282, JString, required = false,
                                 default = nil)
  if valid_774282 != nil:
    section.add "Attributes.0.key", valid_774282
  var valid_774283 = query.getOrDefault("Version")
  valid_774283 = validateParameter(valid_774283, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774283 != nil:
    section.add "Version", valid_774283
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774284 = header.getOrDefault("X-Amz-Date")
  valid_774284 = validateParameter(valid_774284, JString, required = false,
                                 default = nil)
  if valid_774284 != nil:
    section.add "X-Amz-Date", valid_774284
  var valid_774285 = header.getOrDefault("X-Amz-Security-Token")
  valid_774285 = validateParameter(valid_774285, JString, required = false,
                                 default = nil)
  if valid_774285 != nil:
    section.add "X-Amz-Security-Token", valid_774285
  var valid_774286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774286 = validateParameter(valid_774286, JString, required = false,
                                 default = nil)
  if valid_774286 != nil:
    section.add "X-Amz-Content-Sha256", valid_774286
  var valid_774287 = header.getOrDefault("X-Amz-Algorithm")
  valid_774287 = validateParameter(valid_774287, JString, required = false,
                                 default = nil)
  if valid_774287 != nil:
    section.add "X-Amz-Algorithm", valid_774287
  var valid_774288 = header.getOrDefault("X-Amz-Signature")
  valid_774288 = validateParameter(valid_774288, JString, required = false,
                                 default = nil)
  if valid_774288 != nil:
    section.add "X-Amz-Signature", valid_774288
  var valid_774289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "X-Amz-SignedHeaders", valid_774289
  var valid_774290 = header.getOrDefault("X-Amz-Credential")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "X-Amz-Credential", valid_774290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774291: Call_GetSubscribe_774269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_774291.validator(path, query, header, formData, body)
  let scheme = call_774291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774291.url(scheme.get, call_774291.host, call_774291.base,
                         call_774291.route, valid.getOrDefault("path"))
  result = hook(call_774291, url, valid)

proc call*(call_774292: Call_GetSubscribe_774269; Protocol: string; TopicArn: string;
          Attributes2Key: string = ""; Endpoint: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "Subscribe"; ReturnSubscriptionArn: bool = false;
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Attributes2Key: string
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes1Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_774293 = newJObject()
  add(query_774293, "Attributes.2.key", newJString(Attributes2Key))
  add(query_774293, "Endpoint", newJString(Endpoint))
  add(query_774293, "Protocol", newJString(Protocol))
  add(query_774293, "Attributes.1.value", newJString(Attributes1Value))
  add(query_774293, "Attributes.0.value", newJString(Attributes0Value))
  add(query_774293, "Action", newJString(Action))
  add(query_774293, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_774293, "Attributes.1.key", newJString(Attributes1Key))
  add(query_774293, "TopicArn", newJString(TopicArn))
  add(query_774293, "Attributes.2.value", newJString(Attributes2Value))
  add(query_774293, "Attributes.0.key", newJString(Attributes0Key))
  add(query_774293, "Version", newJString(Version))
  result = call_774292.call(nil, query_774293, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_774269(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_774270, base: "/",
    url: url_GetSubscribe_774271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_774337 = ref object of OpenApiRestCall_772597
proc url_PostTagResource_774339(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostTagResource_774338(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774340 = query.getOrDefault("Action")
  valid_774340 = validateParameter(valid_774340, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_774340 != nil:
    section.add "Action", valid_774340
  var valid_774341 = query.getOrDefault("Version")
  valid_774341 = validateParameter(valid_774341, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774341 != nil:
    section.add "Version", valid_774341
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774342 = header.getOrDefault("X-Amz-Date")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "X-Amz-Date", valid_774342
  var valid_774343 = header.getOrDefault("X-Amz-Security-Token")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "X-Amz-Security-Token", valid_774343
  var valid_774344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = nil)
  if valid_774344 != nil:
    section.add "X-Amz-Content-Sha256", valid_774344
  var valid_774345 = header.getOrDefault("X-Amz-Algorithm")
  valid_774345 = validateParameter(valid_774345, JString, required = false,
                                 default = nil)
  if valid_774345 != nil:
    section.add "X-Amz-Algorithm", valid_774345
  var valid_774346 = header.getOrDefault("X-Amz-Signature")
  valid_774346 = validateParameter(valid_774346, JString, required = false,
                                 default = nil)
  if valid_774346 != nil:
    section.add "X-Amz-Signature", valid_774346
  var valid_774347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774347 = validateParameter(valid_774347, JString, required = false,
                                 default = nil)
  if valid_774347 != nil:
    section.add "X-Amz-SignedHeaders", valid_774347
  var valid_774348 = header.getOrDefault("X-Amz-Credential")
  valid_774348 = validateParameter(valid_774348, JString, required = false,
                                 default = nil)
  if valid_774348 != nil:
    section.add "X-Amz-Credential", valid_774348
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_774349 = formData.getOrDefault("Tags")
  valid_774349 = validateParameter(valid_774349, JArray, required = true, default = nil)
  if valid_774349 != nil:
    section.add "Tags", valid_774349
  var valid_774350 = formData.getOrDefault("ResourceArn")
  valid_774350 = validateParameter(valid_774350, JString, required = true,
                                 default = nil)
  if valid_774350 != nil:
    section.add "ResourceArn", valid_774350
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774351: Call_PostTagResource_774337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_774351.validator(path, query, header, formData, body)
  let scheme = call_774351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774351.url(scheme.get, call_774351.host, call_774351.base,
                         call_774351.route, valid.getOrDefault("path"))
  result = hook(call_774351, url, valid)

proc call*(call_774352: Call_PostTagResource_774337; Tags: JsonNode;
          ResourceArn: string; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Version: string (required)
  var query_774353 = newJObject()
  var formData_774354 = newJObject()
  if Tags != nil:
    formData_774354.add "Tags", Tags
  add(query_774353, "Action", newJString(Action))
  add(formData_774354, "ResourceArn", newJString(ResourceArn))
  add(query_774353, "Version", newJString(Version))
  result = call_774352.call(nil, query_774353, nil, formData_774354, nil)

var postTagResource* = Call_PostTagResource_774337(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_774338,
    base: "/", url: url_PostTagResource_774339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_774320 = ref object of OpenApiRestCall_772597
proc url_GetTagResource_774322(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTagResource_774321(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_774323 = query.getOrDefault("ResourceArn")
  valid_774323 = validateParameter(valid_774323, JString, required = true,
                                 default = nil)
  if valid_774323 != nil:
    section.add "ResourceArn", valid_774323
  var valid_774324 = query.getOrDefault("Tags")
  valid_774324 = validateParameter(valid_774324, JArray, required = true, default = nil)
  if valid_774324 != nil:
    section.add "Tags", valid_774324
  var valid_774325 = query.getOrDefault("Action")
  valid_774325 = validateParameter(valid_774325, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_774325 != nil:
    section.add "Action", valid_774325
  var valid_774326 = query.getOrDefault("Version")
  valid_774326 = validateParameter(valid_774326, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774326 != nil:
    section.add "Version", valid_774326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774327 = header.getOrDefault("X-Amz-Date")
  valid_774327 = validateParameter(valid_774327, JString, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "X-Amz-Date", valid_774327
  var valid_774328 = header.getOrDefault("X-Amz-Security-Token")
  valid_774328 = validateParameter(valid_774328, JString, required = false,
                                 default = nil)
  if valid_774328 != nil:
    section.add "X-Amz-Security-Token", valid_774328
  var valid_774329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774329 = validateParameter(valid_774329, JString, required = false,
                                 default = nil)
  if valid_774329 != nil:
    section.add "X-Amz-Content-Sha256", valid_774329
  var valid_774330 = header.getOrDefault("X-Amz-Algorithm")
  valid_774330 = validateParameter(valid_774330, JString, required = false,
                                 default = nil)
  if valid_774330 != nil:
    section.add "X-Amz-Algorithm", valid_774330
  var valid_774331 = header.getOrDefault("X-Amz-Signature")
  valid_774331 = validateParameter(valid_774331, JString, required = false,
                                 default = nil)
  if valid_774331 != nil:
    section.add "X-Amz-Signature", valid_774331
  var valid_774332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774332 = validateParameter(valid_774332, JString, required = false,
                                 default = nil)
  if valid_774332 != nil:
    section.add "X-Amz-SignedHeaders", valid_774332
  var valid_774333 = header.getOrDefault("X-Amz-Credential")
  valid_774333 = validateParameter(valid_774333, JString, required = false,
                                 default = nil)
  if valid_774333 != nil:
    section.add "X-Amz-Credential", valid_774333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774334: Call_GetTagResource_774320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_774334.validator(path, query, header, formData, body)
  let scheme = call_774334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774334.url(scheme.get, call_774334.host, call_774334.base,
                         call_774334.route, valid.getOrDefault("path"))
  result = hook(call_774334, url, valid)

proc call*(call_774335: Call_GetTagResource_774320; ResourceArn: string;
          Tags: JsonNode; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774336 = newJObject()
  add(query_774336, "ResourceArn", newJString(ResourceArn))
  if Tags != nil:
    query_774336.add "Tags", Tags
  add(query_774336, "Action", newJString(Action))
  add(query_774336, "Version", newJString(Version))
  result = call_774335.call(nil, query_774336, nil, nil, nil)

var getTagResource* = Call_GetTagResource_774320(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_774321,
    base: "/", url: url_GetTagResource_774322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_774371 = ref object of OpenApiRestCall_772597
proc url_PostUnsubscribe_774373(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUnsubscribe_774372(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774374 = query.getOrDefault("Action")
  valid_774374 = validateParameter(valid_774374, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_774374 != nil:
    section.add "Action", valid_774374
  var valid_774375 = query.getOrDefault("Version")
  valid_774375 = validateParameter(valid_774375, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774375 != nil:
    section.add "Version", valid_774375
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774376 = header.getOrDefault("X-Amz-Date")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "X-Amz-Date", valid_774376
  var valid_774377 = header.getOrDefault("X-Amz-Security-Token")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "X-Amz-Security-Token", valid_774377
  var valid_774378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774378 = validateParameter(valid_774378, JString, required = false,
                                 default = nil)
  if valid_774378 != nil:
    section.add "X-Amz-Content-Sha256", valid_774378
  var valid_774379 = header.getOrDefault("X-Amz-Algorithm")
  valid_774379 = validateParameter(valid_774379, JString, required = false,
                                 default = nil)
  if valid_774379 != nil:
    section.add "X-Amz-Algorithm", valid_774379
  var valid_774380 = header.getOrDefault("X-Amz-Signature")
  valid_774380 = validateParameter(valid_774380, JString, required = false,
                                 default = nil)
  if valid_774380 != nil:
    section.add "X-Amz-Signature", valid_774380
  var valid_774381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774381 = validateParameter(valid_774381, JString, required = false,
                                 default = nil)
  if valid_774381 != nil:
    section.add "X-Amz-SignedHeaders", valid_774381
  var valid_774382 = header.getOrDefault("X-Amz-Credential")
  valid_774382 = validateParameter(valid_774382, JString, required = false,
                                 default = nil)
  if valid_774382 != nil:
    section.add "X-Amz-Credential", valid_774382
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_774383 = formData.getOrDefault("SubscriptionArn")
  valid_774383 = validateParameter(valid_774383, JString, required = true,
                                 default = nil)
  if valid_774383 != nil:
    section.add "SubscriptionArn", valid_774383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774384: Call_PostUnsubscribe_774371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_774384.validator(path, query, header, formData, body)
  let scheme = call_774384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774384.url(scheme.get, call_774384.host, call_774384.base,
                         call_774384.route, valid.getOrDefault("path"))
  result = hook(call_774384, url, valid)

proc call*(call_774385: Call_PostUnsubscribe_774371; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Version: string (required)
  var query_774386 = newJObject()
  var formData_774387 = newJObject()
  add(query_774386, "Action", newJString(Action))
  add(formData_774387, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_774386, "Version", newJString(Version))
  result = call_774385.call(nil, query_774386, nil, formData_774387, nil)

var postUnsubscribe* = Call_PostUnsubscribe_774371(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_774372,
    base: "/", url: url_PostUnsubscribe_774373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_774355 = ref object of OpenApiRestCall_772597
proc url_GetUnsubscribe_774357(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUnsubscribe_774356(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_774358 = query.getOrDefault("SubscriptionArn")
  valid_774358 = validateParameter(valid_774358, JString, required = true,
                                 default = nil)
  if valid_774358 != nil:
    section.add "SubscriptionArn", valid_774358
  var valid_774359 = query.getOrDefault("Action")
  valid_774359 = validateParameter(valid_774359, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_774359 != nil:
    section.add "Action", valid_774359
  var valid_774360 = query.getOrDefault("Version")
  valid_774360 = validateParameter(valid_774360, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774360 != nil:
    section.add "Version", valid_774360
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774361 = header.getOrDefault("X-Amz-Date")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "X-Amz-Date", valid_774361
  var valid_774362 = header.getOrDefault("X-Amz-Security-Token")
  valid_774362 = validateParameter(valid_774362, JString, required = false,
                                 default = nil)
  if valid_774362 != nil:
    section.add "X-Amz-Security-Token", valid_774362
  var valid_774363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774363 = validateParameter(valid_774363, JString, required = false,
                                 default = nil)
  if valid_774363 != nil:
    section.add "X-Amz-Content-Sha256", valid_774363
  var valid_774364 = header.getOrDefault("X-Amz-Algorithm")
  valid_774364 = validateParameter(valid_774364, JString, required = false,
                                 default = nil)
  if valid_774364 != nil:
    section.add "X-Amz-Algorithm", valid_774364
  var valid_774365 = header.getOrDefault("X-Amz-Signature")
  valid_774365 = validateParameter(valid_774365, JString, required = false,
                                 default = nil)
  if valid_774365 != nil:
    section.add "X-Amz-Signature", valid_774365
  var valid_774366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774366 = validateParameter(valid_774366, JString, required = false,
                                 default = nil)
  if valid_774366 != nil:
    section.add "X-Amz-SignedHeaders", valid_774366
  var valid_774367 = header.getOrDefault("X-Amz-Credential")
  valid_774367 = validateParameter(valid_774367, JString, required = false,
                                 default = nil)
  if valid_774367 != nil:
    section.add "X-Amz-Credential", valid_774367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774368: Call_GetUnsubscribe_774355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_774368.validator(path, query, header, formData, body)
  let scheme = call_774368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774368.url(scheme.get, call_774368.host, call_774368.base,
                         call_774368.route, valid.getOrDefault("path"))
  result = hook(call_774368, url, valid)

proc call*(call_774369: Call_GetUnsubscribe_774355; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774370 = newJObject()
  add(query_774370, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_774370, "Action", newJString(Action))
  add(query_774370, "Version", newJString(Version))
  result = call_774369.call(nil, query_774370, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_774355(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_774356,
    base: "/", url: url_GetUnsubscribe_774357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_774405 = ref object of OpenApiRestCall_772597
proc url_PostUntagResource_774407(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUntagResource_774406(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774408 = query.getOrDefault("Action")
  valid_774408 = validateParameter(valid_774408, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_774408 != nil:
    section.add "Action", valid_774408
  var valid_774409 = query.getOrDefault("Version")
  valid_774409 = validateParameter(valid_774409, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774409 != nil:
    section.add "Version", valid_774409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774410 = header.getOrDefault("X-Amz-Date")
  valid_774410 = validateParameter(valid_774410, JString, required = false,
                                 default = nil)
  if valid_774410 != nil:
    section.add "X-Amz-Date", valid_774410
  var valid_774411 = header.getOrDefault("X-Amz-Security-Token")
  valid_774411 = validateParameter(valid_774411, JString, required = false,
                                 default = nil)
  if valid_774411 != nil:
    section.add "X-Amz-Security-Token", valid_774411
  var valid_774412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774412 = validateParameter(valid_774412, JString, required = false,
                                 default = nil)
  if valid_774412 != nil:
    section.add "X-Amz-Content-Sha256", valid_774412
  var valid_774413 = header.getOrDefault("X-Amz-Algorithm")
  valid_774413 = validateParameter(valid_774413, JString, required = false,
                                 default = nil)
  if valid_774413 != nil:
    section.add "X-Amz-Algorithm", valid_774413
  var valid_774414 = header.getOrDefault("X-Amz-Signature")
  valid_774414 = validateParameter(valid_774414, JString, required = false,
                                 default = nil)
  if valid_774414 != nil:
    section.add "X-Amz-Signature", valid_774414
  var valid_774415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774415 = validateParameter(valid_774415, JString, required = false,
                                 default = nil)
  if valid_774415 != nil:
    section.add "X-Amz-SignedHeaders", valid_774415
  var valid_774416 = header.getOrDefault("X-Amz-Credential")
  valid_774416 = validateParameter(valid_774416, JString, required = false,
                                 default = nil)
  if valid_774416 != nil:
    section.add "X-Amz-Credential", valid_774416
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_774417 = formData.getOrDefault("TagKeys")
  valid_774417 = validateParameter(valid_774417, JArray, required = true, default = nil)
  if valid_774417 != nil:
    section.add "TagKeys", valid_774417
  var valid_774418 = formData.getOrDefault("ResourceArn")
  valid_774418 = validateParameter(valid_774418, JString, required = true,
                                 default = nil)
  if valid_774418 != nil:
    section.add "ResourceArn", valid_774418
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774419: Call_PostUntagResource_774405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_774419.validator(path, query, header, formData, body)
  let scheme = call_774419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774419.url(scheme.get, call_774419.host, call_774419.base,
                         call_774419.route, valid.getOrDefault("path"))
  result = hook(call_774419, url, valid)

proc call*(call_774420: Call_PostUntagResource_774405; TagKeys: JsonNode;
          ResourceArn: string; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Version: string (required)
  var query_774421 = newJObject()
  var formData_774422 = newJObject()
  add(query_774421, "Action", newJString(Action))
  if TagKeys != nil:
    formData_774422.add "TagKeys", TagKeys
  add(formData_774422, "ResourceArn", newJString(ResourceArn))
  add(query_774421, "Version", newJString(Version))
  result = call_774420.call(nil, query_774421, nil, formData_774422, nil)

var postUntagResource* = Call_PostUntagResource_774405(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_774406,
    base: "/", url: url_PostUntagResource_774407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_774388 = ref object of OpenApiRestCall_772597
proc url_GetUntagResource_774390(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUntagResource_774389(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_774391 = query.getOrDefault("ResourceArn")
  valid_774391 = validateParameter(valid_774391, JString, required = true,
                                 default = nil)
  if valid_774391 != nil:
    section.add "ResourceArn", valid_774391
  var valid_774392 = query.getOrDefault("Action")
  valid_774392 = validateParameter(valid_774392, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_774392 != nil:
    section.add "Action", valid_774392
  var valid_774393 = query.getOrDefault("TagKeys")
  valid_774393 = validateParameter(valid_774393, JArray, required = true, default = nil)
  if valid_774393 != nil:
    section.add "TagKeys", valid_774393
  var valid_774394 = query.getOrDefault("Version")
  valid_774394 = validateParameter(valid_774394, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_774394 != nil:
    section.add "Version", valid_774394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774395 = header.getOrDefault("X-Amz-Date")
  valid_774395 = validateParameter(valid_774395, JString, required = false,
                                 default = nil)
  if valid_774395 != nil:
    section.add "X-Amz-Date", valid_774395
  var valid_774396 = header.getOrDefault("X-Amz-Security-Token")
  valid_774396 = validateParameter(valid_774396, JString, required = false,
                                 default = nil)
  if valid_774396 != nil:
    section.add "X-Amz-Security-Token", valid_774396
  var valid_774397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774397 = validateParameter(valid_774397, JString, required = false,
                                 default = nil)
  if valid_774397 != nil:
    section.add "X-Amz-Content-Sha256", valid_774397
  var valid_774398 = header.getOrDefault("X-Amz-Algorithm")
  valid_774398 = validateParameter(valid_774398, JString, required = false,
                                 default = nil)
  if valid_774398 != nil:
    section.add "X-Amz-Algorithm", valid_774398
  var valid_774399 = header.getOrDefault("X-Amz-Signature")
  valid_774399 = validateParameter(valid_774399, JString, required = false,
                                 default = nil)
  if valid_774399 != nil:
    section.add "X-Amz-Signature", valid_774399
  var valid_774400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774400 = validateParameter(valid_774400, JString, required = false,
                                 default = nil)
  if valid_774400 != nil:
    section.add "X-Amz-SignedHeaders", valid_774400
  var valid_774401 = header.getOrDefault("X-Amz-Credential")
  valid_774401 = validateParameter(valid_774401, JString, required = false,
                                 default = nil)
  if valid_774401 != nil:
    section.add "X-Amz-Credential", valid_774401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774402: Call_GetUntagResource_774388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_774402.validator(path, query, header, formData, body)
  let scheme = call_774402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774402.url(scheme.get, call_774402.host, call_774402.base,
                         call_774402.route, valid.getOrDefault("path"))
  result = hook(call_774402, url, valid)

proc call*(call_774403: Call_GetUntagResource_774388; ResourceArn: string;
          TagKeys: JsonNode; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   Version: string (required)
  var query_774404 = newJObject()
  add(query_774404, "ResourceArn", newJString(ResourceArn))
  add(query_774404, "Action", newJString(Action))
  if TagKeys != nil:
    query_774404.add "TagKeys", TagKeys
  add(query_774404, "Version", newJString(Version))
  result = call_774403.call(nil, query_774404, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_774388(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_774389,
    base: "/", url: url_GetUntagResource_774390,
    schemes: {Scheme.Https, Scheme.Http})
proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
