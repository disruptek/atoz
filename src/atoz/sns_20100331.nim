
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_611270 = ref object of OpenApiRestCall_610658
proc url_PostAddPermission_611272(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddPermission_611271(path: JsonNode; query: JsonNode;
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
  var valid_611273 = query.getOrDefault("Action")
  valid_611273 = validateParameter(valid_611273, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_611273 != nil:
    section.add "Action", valid_611273
  var valid_611274 = query.getOrDefault("Version")
  valid_611274 = validateParameter(valid_611274, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611274 != nil:
    section.add "Version", valid_611274
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611275 = header.getOrDefault("X-Amz-Signature")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Signature", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Content-Sha256", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Date")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Date", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Credential")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Credential", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Security-Token")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Security-Token", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Algorithm")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Algorithm", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-SignedHeaders", valid_611281
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_611282 = formData.getOrDefault("TopicArn")
  valid_611282 = validateParameter(valid_611282, JString, required = true,
                                 default = nil)
  if valid_611282 != nil:
    section.add "TopicArn", valid_611282
  var valid_611283 = formData.getOrDefault("AWSAccountId")
  valid_611283 = validateParameter(valid_611283, JArray, required = true, default = nil)
  if valid_611283 != nil:
    section.add "AWSAccountId", valid_611283
  var valid_611284 = formData.getOrDefault("Label")
  valid_611284 = validateParameter(valid_611284, JString, required = true,
                                 default = nil)
  if valid_611284 != nil:
    section.add "Label", valid_611284
  var valid_611285 = formData.getOrDefault("ActionName")
  valid_611285 = validateParameter(valid_611285, JArray, required = true, default = nil)
  if valid_611285 != nil:
    section.add "ActionName", valid_611285
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611286: Call_PostAddPermission_611270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_611286.validator(path, query, header, formData, body)
  let scheme = call_611286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611286.url(scheme.get, call_611286.host, call_611286.base,
                         call_611286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611286, url, valid)

proc call*(call_611287: Call_PostAddPermission_611270; TopicArn: string;
          AWSAccountId: JsonNode; Label: string; ActionName: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## postAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  ##   Version: string (required)
  var query_611288 = newJObject()
  var formData_611289 = newJObject()
  add(formData_611289, "TopicArn", newJString(TopicArn))
  add(query_611288, "Action", newJString(Action))
  if AWSAccountId != nil:
    formData_611289.add "AWSAccountId", AWSAccountId
  add(formData_611289, "Label", newJString(Label))
  if ActionName != nil:
    formData_611289.add "ActionName", ActionName
  add(query_611288, "Version", newJString(Version))
  result = call_611287.call(nil, query_611288, nil, formData_611289, nil)

var postAddPermission* = Call_PostAddPermission_611270(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_611271,
    base: "/", url: url_PostAddPermission_611272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_610996 = ref object of OpenApiRestCall_610658
proc url_GetAddPermission_610998(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddPermission_610997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: JString (required)
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  ##   Version: JString (required)
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TopicArn` field"
  var valid_611110 = query.getOrDefault("TopicArn")
  valid_611110 = validateParameter(valid_611110, JString, required = true,
                                 default = nil)
  if valid_611110 != nil:
    section.add "TopicArn", valid_611110
  var valid_611124 = query.getOrDefault("Action")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_611124 != nil:
    section.add "Action", valid_611124
  var valid_611125 = query.getOrDefault("ActionName")
  valid_611125 = validateParameter(valid_611125, JArray, required = true, default = nil)
  if valid_611125 != nil:
    section.add "ActionName", valid_611125
  var valid_611126 = query.getOrDefault("Version")
  valid_611126 = validateParameter(valid_611126, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611126 != nil:
    section.add "Version", valid_611126
  var valid_611127 = query.getOrDefault("AWSAccountId")
  valid_611127 = validateParameter(valid_611127, JArray, required = true, default = nil)
  if valid_611127 != nil:
    section.add "AWSAccountId", valid_611127
  var valid_611128 = query.getOrDefault("Label")
  valid_611128 = validateParameter(valid_611128, JString, required = true,
                                 default = nil)
  if valid_611128 != nil:
    section.add "Label", valid_611128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611129 = header.getOrDefault("X-Amz-Signature")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Signature", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Content-Sha256", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Date")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Date", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-Credential")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-Credential", valid_611132
  var valid_611133 = header.getOrDefault("X-Amz-Security-Token")
  valid_611133 = validateParameter(valid_611133, JString, required = false,
                                 default = nil)
  if valid_611133 != nil:
    section.add "X-Amz-Security-Token", valid_611133
  var valid_611134 = header.getOrDefault("X-Amz-Algorithm")
  valid_611134 = validateParameter(valid_611134, JString, required = false,
                                 default = nil)
  if valid_611134 != nil:
    section.add "X-Amz-Algorithm", valid_611134
  var valid_611135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611135 = validateParameter(valid_611135, JString, required = false,
                                 default = nil)
  if valid_611135 != nil:
    section.add "X-Amz-SignedHeaders", valid_611135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611158: Call_GetAddPermission_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_611158.validator(path, query, header, formData, body)
  let scheme = call_611158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611158.url(scheme.get, call_611158.host, call_611158.base,
                         call_611158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611158, url, valid)

proc call*(call_611229: Call_GetAddPermission_610996; TopicArn: string;
          ActionName: JsonNode; AWSAccountId: JsonNode; Label: string;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## getAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  ##   Version: string (required)
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  var query_611230 = newJObject()
  add(query_611230, "TopicArn", newJString(TopicArn))
  add(query_611230, "Action", newJString(Action))
  if ActionName != nil:
    query_611230.add "ActionName", ActionName
  add(query_611230, "Version", newJString(Version))
  if AWSAccountId != nil:
    query_611230.add "AWSAccountId", AWSAccountId
  add(query_611230, "Label", newJString(Label))
  result = call_611229.call(nil, query_611230, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_610996(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_610997,
    base: "/", url: url_GetAddPermission_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_611306 = ref object of OpenApiRestCall_610658
proc url_PostCheckIfPhoneNumberIsOptedOut_611308(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCheckIfPhoneNumberIsOptedOut_611307(path: JsonNode;
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
  var valid_611309 = query.getOrDefault("Action")
  valid_611309 = validateParameter(valid_611309, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_611309 != nil:
    section.add "Action", valid_611309
  var valid_611310 = query.getOrDefault("Version")
  valid_611310 = validateParameter(valid_611310, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611310 != nil:
    section.add "Version", valid_611310
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611311 = header.getOrDefault("X-Amz-Signature")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Signature", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Content-Sha256", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Date")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Date", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Credential")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Credential", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Security-Token")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Security-Token", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Algorithm")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Algorithm", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-SignedHeaders", valid_611317
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_611318 = formData.getOrDefault("phoneNumber")
  valid_611318 = validateParameter(valid_611318, JString, required = true,
                                 default = nil)
  if valid_611318 != nil:
    section.add "phoneNumber", valid_611318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611319: Call_PostCheckIfPhoneNumberIsOptedOut_611306;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_611319.validator(path, query, header, formData, body)
  let scheme = call_611319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611319.url(scheme.get, call_611319.host, call_611319.base,
                         call_611319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611319, url, valid)

proc call*(call_611320: Call_PostCheckIfPhoneNumberIsOptedOut_611306;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611321 = newJObject()
  var formData_611322 = newJObject()
  add(formData_611322, "phoneNumber", newJString(phoneNumber))
  add(query_611321, "Action", newJString(Action))
  add(query_611321, "Version", newJString(Version))
  result = call_611320.call(nil, query_611321, nil, formData_611322, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_611306(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_611307, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_611308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_611290 = ref object of OpenApiRestCall_610658
proc url_GetCheckIfPhoneNumberIsOptedOut_611292(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCheckIfPhoneNumberIsOptedOut_611291(path: JsonNode;
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
  var valid_611293 = query.getOrDefault("phoneNumber")
  valid_611293 = validateParameter(valid_611293, JString, required = true,
                                 default = nil)
  if valid_611293 != nil:
    section.add "phoneNumber", valid_611293
  var valid_611294 = query.getOrDefault("Action")
  valid_611294 = validateParameter(valid_611294, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_611294 != nil:
    section.add "Action", valid_611294
  var valid_611295 = query.getOrDefault("Version")
  valid_611295 = validateParameter(valid_611295, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611295 != nil:
    section.add "Version", valid_611295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611296 = header.getOrDefault("X-Amz-Signature")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Signature", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Content-Sha256", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Date")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Date", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Credential")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Credential", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Security-Token")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Security-Token", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Algorithm")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Algorithm", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-SignedHeaders", valid_611302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611303: Call_GetCheckIfPhoneNumberIsOptedOut_611290;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_611303.validator(path, query, header, formData, body)
  let scheme = call_611303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611303.url(scheme.get, call_611303.host, call_611303.base,
                         call_611303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611303, url, valid)

proc call*(call_611304: Call_GetCheckIfPhoneNumberIsOptedOut_611290;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611305 = newJObject()
  add(query_611305, "phoneNumber", newJString(phoneNumber))
  add(query_611305, "Action", newJString(Action))
  add(query_611305, "Version", newJString(Version))
  result = call_611304.call(nil, query_611305, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_611290(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_611291, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_611292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_611341 = ref object of OpenApiRestCall_610658
proc url_PostConfirmSubscription_611343(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostConfirmSubscription_611342(path: JsonNode; query: JsonNode;
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
  var valid_611344 = query.getOrDefault("Action")
  valid_611344 = validateParameter(valid_611344, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_611344 != nil:
    section.add "Action", valid_611344
  var valid_611345 = query.getOrDefault("Version")
  valid_611345 = validateParameter(valid_611345, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611345 != nil:
    section.add "Version", valid_611345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611346 = header.getOrDefault("X-Amz-Signature")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Signature", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Content-Sha256", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Date")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Date", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Credential")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Credential", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Security-Token")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Security-Token", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Algorithm")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Algorithm", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-SignedHeaders", valid_611352
  result.add "header", section
  ## parameters in `formData` object:
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  section = newJObject()
  var valid_611353 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_611353
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_611354 = formData.getOrDefault("TopicArn")
  valid_611354 = validateParameter(valid_611354, JString, required = true,
                                 default = nil)
  if valid_611354 != nil:
    section.add "TopicArn", valid_611354
  var valid_611355 = formData.getOrDefault("Token")
  valid_611355 = validateParameter(valid_611355, JString, required = true,
                                 default = nil)
  if valid_611355 != nil:
    section.add "Token", valid_611355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611356: Call_PostConfirmSubscription_611341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_611356.validator(path, query, header, formData, body)
  let scheme = call_611356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611356.url(scheme.get, call_611356.host, call_611356.base,
                         call_611356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611356, url, valid)

proc call*(call_611357: Call_PostConfirmSubscription_611341; TopicArn: string;
          Token: string; AuthenticateOnUnsubscribe: string = "";
          Action: string = "ConfirmSubscription"; Version: string = "2010-03-31"): Recallable =
  ## postConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611358 = newJObject()
  var formData_611359 = newJObject()
  add(formData_611359, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(formData_611359, "TopicArn", newJString(TopicArn))
  add(formData_611359, "Token", newJString(Token))
  add(query_611358, "Action", newJString(Action))
  add(query_611358, "Version", newJString(Version))
  result = call_611357.call(nil, query_611358, nil, formData_611359, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_611341(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_611342, base: "/",
    url: url_PostConfirmSubscription_611343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_611323 = ref object of OpenApiRestCall_610658
proc url_GetConfirmSubscription_611325(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConfirmSubscription_611324(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  section = newJObject()
  var valid_611326 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_611326
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_611327 = query.getOrDefault("Token")
  valid_611327 = validateParameter(valid_611327, JString, required = true,
                                 default = nil)
  if valid_611327 != nil:
    section.add "Token", valid_611327
  var valid_611328 = query.getOrDefault("Action")
  valid_611328 = validateParameter(valid_611328, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_611328 != nil:
    section.add "Action", valid_611328
  var valid_611329 = query.getOrDefault("Version")
  valid_611329 = validateParameter(valid_611329, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611329 != nil:
    section.add "Version", valid_611329
  var valid_611330 = query.getOrDefault("TopicArn")
  valid_611330 = validateParameter(valid_611330, JString, required = true,
                                 default = nil)
  if valid_611330 != nil:
    section.add "TopicArn", valid_611330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611331 = header.getOrDefault("X-Amz-Signature")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Signature", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Content-Sha256", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Date")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Date", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Credential")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Credential", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Security-Token")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Security-Token", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Algorithm")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Algorithm", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-SignedHeaders", valid_611337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611338: Call_GetConfirmSubscription_611323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_611338.validator(path, query, header, formData, body)
  let scheme = call_611338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611338.url(scheme.get, call_611338.host, call_611338.base,
                         call_611338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611338, url, valid)

proc call*(call_611339: Call_GetConfirmSubscription_611323; Token: string;
          TopicArn: string; AuthenticateOnUnsubscribe: string = "";
          Action: string = "ConfirmSubscription"; Version: string = "2010-03-31"): Recallable =
  ## getConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  var query_611340 = newJObject()
  add(query_611340, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_611340, "Token", newJString(Token))
  add(query_611340, "Action", newJString(Action))
  add(query_611340, "Version", newJString(Version))
  add(query_611340, "TopicArn", newJString(TopicArn))
  result = call_611339.call(nil, query_611340, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_611323(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_611324, base: "/",
    url: url_GetConfirmSubscription_611325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_611383 = ref object of OpenApiRestCall_610658
proc url_PostCreatePlatformApplication_611385(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreatePlatformApplication_611384(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611386 = query.getOrDefault("Action")
  valid_611386 = validateParameter(valid_611386, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_611386 != nil:
    section.add "Action", valid_611386
  var valid_611387 = query.getOrDefault("Version")
  valid_611387 = validateParameter(valid_611387, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611387 != nil:
    section.add "Version", valid_611387
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611388 = header.getOrDefault("X-Amz-Signature")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Signature", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Content-Sha256", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Date")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Date", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Credential")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Credential", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Security-Token")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Security-Token", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Algorithm")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Algorithm", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-SignedHeaders", valid_611394
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.key: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_611395 = formData.getOrDefault("Attributes.0.key")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "Attributes.0.key", valid_611395
  assert formData != nil,
        "formData argument is necessary due to required `Platform` field"
  var valid_611396 = formData.getOrDefault("Platform")
  valid_611396 = validateParameter(valid_611396, JString, required = true,
                                 default = nil)
  if valid_611396 != nil:
    section.add "Platform", valid_611396
  var valid_611397 = formData.getOrDefault("Attributes.2.value")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "Attributes.2.value", valid_611397
  var valid_611398 = formData.getOrDefault("Attributes.2.key")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "Attributes.2.key", valid_611398
  var valid_611399 = formData.getOrDefault("Attributes.0.value")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "Attributes.0.value", valid_611399
  var valid_611400 = formData.getOrDefault("Attributes.1.key")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "Attributes.1.key", valid_611400
  var valid_611401 = formData.getOrDefault("Name")
  valid_611401 = validateParameter(valid_611401, JString, required = true,
                                 default = nil)
  if valid_611401 != nil:
    section.add "Name", valid_611401
  var valid_611402 = formData.getOrDefault("Attributes.1.value")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "Attributes.1.value", valid_611402
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611403: Call_PostCreatePlatformApplication_611383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_611403.validator(path, query, header, formData, body)
  let scheme = call_611403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611403.url(scheme.get, call_611403.host, call_611403.base,
                         call_611403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611403, url, valid)

proc call*(call_611404: Call_PostCreatePlatformApplication_611383;
          Platform: string; Name: string; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformApplication";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ##   Attributes0Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_611405 = newJObject()
  var formData_611406 = newJObject()
  add(formData_611406, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_611406, "Platform", newJString(Platform))
  add(formData_611406, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_611406, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_611406, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_611406, "Attributes.1.key", newJString(Attributes1Key))
  add(query_611405, "Action", newJString(Action))
  add(formData_611406, "Name", newJString(Name))
  add(query_611405, "Version", newJString(Version))
  add(formData_611406, "Attributes.1.value", newJString(Attributes1Value))
  result = call_611404.call(nil, query_611405, nil, formData_611406, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_611383(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_611384, base: "/",
    url: url_PostCreatePlatformApplication_611385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_611360 = ref object of OpenApiRestCall_610658
proc url_GetCreatePlatformApplication_611362(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreatePlatformApplication_611361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_611363 = query.getOrDefault("Attributes.1.key")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "Attributes.1.key", valid_611363
  var valid_611364 = query.getOrDefault("Attributes.0.value")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "Attributes.0.value", valid_611364
  var valid_611365 = query.getOrDefault("Attributes.0.key")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "Attributes.0.key", valid_611365
  assert query != nil,
        "query argument is necessary due to required `Platform` field"
  var valid_611366 = query.getOrDefault("Platform")
  valid_611366 = validateParameter(valid_611366, JString, required = true,
                                 default = nil)
  if valid_611366 != nil:
    section.add "Platform", valid_611366
  var valid_611367 = query.getOrDefault("Attributes.2.value")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "Attributes.2.value", valid_611367
  var valid_611368 = query.getOrDefault("Attributes.1.value")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "Attributes.1.value", valid_611368
  var valid_611369 = query.getOrDefault("Name")
  valid_611369 = validateParameter(valid_611369, JString, required = true,
                                 default = nil)
  if valid_611369 != nil:
    section.add "Name", valid_611369
  var valid_611370 = query.getOrDefault("Action")
  valid_611370 = validateParameter(valid_611370, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_611370 != nil:
    section.add "Action", valid_611370
  var valid_611371 = query.getOrDefault("Version")
  valid_611371 = validateParameter(valid_611371, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611371 != nil:
    section.add "Version", valid_611371
  var valid_611372 = query.getOrDefault("Attributes.2.key")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "Attributes.2.key", valid_611372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611373 = header.getOrDefault("X-Amz-Signature")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Signature", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Content-Sha256", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Date")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Date", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Credential")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Credential", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Security-Token")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Security-Token", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Algorithm")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Algorithm", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-SignedHeaders", valid_611379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611380: Call_GetCreatePlatformApplication_611360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_611380.validator(path, query, header, formData, body)
  let scheme = call_611380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611380.url(scheme.get, call_611380.host, call_611380.base,
                         call_611380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611380, url, valid)

proc call*(call_611381: Call_GetCreatePlatformApplication_611360; Platform: string;
          Name: string; Attributes1Key: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes1Value: string = "";
          Action: string = "CreatePlatformApplication";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_611382 = newJObject()
  add(query_611382, "Attributes.1.key", newJString(Attributes1Key))
  add(query_611382, "Attributes.0.value", newJString(Attributes0Value))
  add(query_611382, "Attributes.0.key", newJString(Attributes0Key))
  add(query_611382, "Platform", newJString(Platform))
  add(query_611382, "Attributes.2.value", newJString(Attributes2Value))
  add(query_611382, "Attributes.1.value", newJString(Attributes1Value))
  add(query_611382, "Name", newJString(Name))
  add(query_611382, "Action", newJString(Action))
  add(query_611382, "Version", newJString(Version))
  add(query_611382, "Attributes.2.key", newJString(Attributes2Key))
  result = call_611381.call(nil, query_611382, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_611360(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_611361, base: "/",
    url: url_GetCreatePlatformApplication_611362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_611431 = ref object of OpenApiRestCall_610658
proc url_PostCreatePlatformEndpoint_611433(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreatePlatformEndpoint_611432(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611434 = query.getOrDefault("Action")
  valid_611434 = validateParameter(valid_611434, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_611434 != nil:
    section.add "Action", valid_611434
  var valid_611435 = query.getOrDefault("Version")
  valid_611435 = validateParameter(valid_611435, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611435 != nil:
    section.add "Version", valid_611435
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611436 = header.getOrDefault("X-Amz-Signature")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Signature", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Content-Sha256", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Date")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Date", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Credential")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Credential", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Security-Token")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Security-Token", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Algorithm")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Algorithm", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-SignedHeaders", valid_611442
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_611443 = formData.getOrDefault("PlatformApplicationArn")
  valid_611443 = validateParameter(valid_611443, JString, required = true,
                                 default = nil)
  if valid_611443 != nil:
    section.add "PlatformApplicationArn", valid_611443
  var valid_611444 = formData.getOrDefault("CustomUserData")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "CustomUserData", valid_611444
  var valid_611445 = formData.getOrDefault("Attributes.0.key")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "Attributes.0.key", valid_611445
  var valid_611446 = formData.getOrDefault("Attributes.2.value")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "Attributes.2.value", valid_611446
  var valid_611447 = formData.getOrDefault("Attributes.2.key")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "Attributes.2.key", valid_611447
  var valid_611448 = formData.getOrDefault("Attributes.0.value")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "Attributes.0.value", valid_611448
  var valid_611449 = formData.getOrDefault("Attributes.1.key")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "Attributes.1.key", valid_611449
  var valid_611450 = formData.getOrDefault("Token")
  valid_611450 = validateParameter(valid_611450, JString, required = true,
                                 default = nil)
  if valid_611450 != nil:
    section.add "Token", valid_611450
  var valid_611451 = formData.getOrDefault("Attributes.1.value")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "Attributes.1.value", valid_611451
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611452: Call_PostCreatePlatformEndpoint_611431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_611452.validator(path, query, header, formData, body)
  let scheme = call_611452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611452.url(scheme.get, call_611452.host, call_611452.base,
                         call_611452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611452, url, valid)

proc call*(call_611453: Call_PostCreatePlatformEndpoint_611431;
          PlatformApplicationArn: string; Token: string;
          CustomUserData: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformEndpoint"; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_611454 = newJObject()
  var formData_611455 = newJObject()
  add(formData_611455, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_611455, "CustomUserData", newJString(CustomUserData))
  add(formData_611455, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_611455, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_611455, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_611455, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_611455, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_611455, "Token", newJString(Token))
  add(query_611454, "Action", newJString(Action))
  add(query_611454, "Version", newJString(Version))
  add(formData_611455, "Attributes.1.value", newJString(Attributes1Value))
  result = call_611453.call(nil, query_611454, nil, formData_611455, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_611431(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_611432, base: "/",
    url: url_PostCreatePlatformEndpoint_611433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_611407 = ref object of OpenApiRestCall_610658
proc url_GetCreatePlatformEndpoint_611409(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreatePlatformEndpoint_611408(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes.1.value: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_611410 = query.getOrDefault("Attributes.1.key")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "Attributes.1.key", valid_611410
  var valid_611411 = query.getOrDefault("CustomUserData")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "CustomUserData", valid_611411
  var valid_611412 = query.getOrDefault("Attributes.0.value")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "Attributes.0.value", valid_611412
  var valid_611413 = query.getOrDefault("Attributes.0.key")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "Attributes.0.key", valid_611413
  var valid_611414 = query.getOrDefault("Attributes.2.value")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "Attributes.2.value", valid_611414
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_611415 = query.getOrDefault("Token")
  valid_611415 = validateParameter(valid_611415, JString, required = true,
                                 default = nil)
  if valid_611415 != nil:
    section.add "Token", valid_611415
  var valid_611416 = query.getOrDefault("Attributes.1.value")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "Attributes.1.value", valid_611416
  var valid_611417 = query.getOrDefault("PlatformApplicationArn")
  valid_611417 = validateParameter(valid_611417, JString, required = true,
                                 default = nil)
  if valid_611417 != nil:
    section.add "PlatformApplicationArn", valid_611417
  var valid_611418 = query.getOrDefault("Action")
  valid_611418 = validateParameter(valid_611418, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_611418 != nil:
    section.add "Action", valid_611418
  var valid_611419 = query.getOrDefault("Version")
  valid_611419 = validateParameter(valid_611419, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611419 != nil:
    section.add "Version", valid_611419
  var valid_611420 = query.getOrDefault("Attributes.2.key")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "Attributes.2.key", valid_611420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611421 = header.getOrDefault("X-Amz-Signature")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Signature", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Content-Sha256", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Date")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Date", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Credential")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Credential", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Security-Token")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Security-Token", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Algorithm")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Algorithm", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-SignedHeaders", valid_611427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611428: Call_GetCreatePlatformEndpoint_611407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_611428.validator(path, query, header, formData, body)
  let scheme = call_611428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611428.url(scheme.get, call_611428.host, call_611428.base,
                         call_611428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611428, url, valid)

proc call*(call_611429: Call_GetCreatePlatformEndpoint_611407; Token: string;
          PlatformApplicationArn: string; Attributes1Key: string = "";
          CustomUserData: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes1Value: string = ""; Action: string = "CreatePlatformEndpoint";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   Attributes1Key: string
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes1Value: string
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_611430 = newJObject()
  add(query_611430, "Attributes.1.key", newJString(Attributes1Key))
  add(query_611430, "CustomUserData", newJString(CustomUserData))
  add(query_611430, "Attributes.0.value", newJString(Attributes0Value))
  add(query_611430, "Attributes.0.key", newJString(Attributes0Key))
  add(query_611430, "Attributes.2.value", newJString(Attributes2Value))
  add(query_611430, "Token", newJString(Token))
  add(query_611430, "Attributes.1.value", newJString(Attributes1Value))
  add(query_611430, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_611430, "Action", newJString(Action))
  add(query_611430, "Version", newJString(Version))
  add(query_611430, "Attributes.2.key", newJString(Attributes2Key))
  result = call_611429.call(nil, query_611430, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_611407(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_611408, base: "/",
    url: url_GetCreatePlatformEndpoint_611409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_611479 = ref object of OpenApiRestCall_610658
proc url_PostCreateTopic_611481(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateTopic_611480(path: JsonNode; query: JsonNode;
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
  var valid_611482 = query.getOrDefault("Action")
  valid_611482 = validateParameter(valid_611482, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_611482 != nil:
    section.add "Action", valid_611482
  var valid_611483 = query.getOrDefault("Version")
  valid_611483 = validateParameter(valid_611483, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611483 != nil:
    section.add "Version", valid_611483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611484 = header.getOrDefault("X-Amz-Signature")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Signature", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Content-Sha256", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Date")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Date", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Credential")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Credential", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Security-Token")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Security-Token", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Algorithm")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Algorithm", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-SignedHeaders", valid_611490
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Tags: JArray
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_611491 = formData.getOrDefault("Attributes.0.key")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "Attributes.0.key", valid_611491
  var valid_611492 = formData.getOrDefault("Attributes.2.value")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "Attributes.2.value", valid_611492
  var valid_611493 = formData.getOrDefault("Attributes.2.key")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "Attributes.2.key", valid_611493
  var valid_611494 = formData.getOrDefault("Attributes.0.value")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "Attributes.0.value", valid_611494
  var valid_611495 = formData.getOrDefault("Attributes.1.key")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "Attributes.1.key", valid_611495
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_611496 = formData.getOrDefault("Name")
  valid_611496 = validateParameter(valid_611496, JString, required = true,
                                 default = nil)
  if valid_611496 != nil:
    section.add "Name", valid_611496
  var valid_611497 = formData.getOrDefault("Tags")
  valid_611497 = validateParameter(valid_611497, JArray, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "Tags", valid_611497
  var valid_611498 = formData.getOrDefault("Attributes.1.value")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "Attributes.1.value", valid_611498
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611499: Call_PostCreateTopic_611479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_611499.validator(path, query, header, formData, body)
  let scheme = call_611499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611499.url(scheme.get, call_611499.host, call_611499.base,
                         call_611499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611499, url, valid)

proc call*(call_611500: Call_PostCreateTopic_611479; Name: string;
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Attributes0Value: string = "";
          Attributes1Key: string = ""; Action: string = "CreateTopic";
          Tags: JsonNode = nil; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Tags: JArray
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_611501 = newJObject()
  var formData_611502 = newJObject()
  add(formData_611502, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_611502, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_611502, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_611502, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_611502, "Attributes.1.key", newJString(Attributes1Key))
  add(query_611501, "Action", newJString(Action))
  add(formData_611502, "Name", newJString(Name))
  if Tags != nil:
    formData_611502.add "Tags", Tags
  add(query_611501, "Version", newJString(Version))
  add(formData_611502, "Attributes.1.value", newJString(Attributes1Value))
  result = call_611500.call(nil, query_611501, nil, formData_611502, nil)

var postCreateTopic* = Call_PostCreateTopic_611479(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_611480,
    base: "/", url: url_PostCreateTopic_611481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_611456 = ref object of OpenApiRestCall_610658
proc url_GetCreateTopic_611458(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateTopic_611457(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Tags: JArray
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_611459 = query.getOrDefault("Attributes.1.key")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "Attributes.1.key", valid_611459
  var valid_611460 = query.getOrDefault("Attributes.0.value")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "Attributes.0.value", valid_611460
  var valid_611461 = query.getOrDefault("Attributes.0.key")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "Attributes.0.key", valid_611461
  var valid_611462 = query.getOrDefault("Tags")
  valid_611462 = validateParameter(valid_611462, JArray, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "Tags", valid_611462
  var valid_611463 = query.getOrDefault("Attributes.2.value")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "Attributes.2.value", valid_611463
  var valid_611464 = query.getOrDefault("Attributes.1.value")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "Attributes.1.value", valid_611464
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_611465 = query.getOrDefault("Name")
  valid_611465 = validateParameter(valid_611465, JString, required = true,
                                 default = nil)
  if valid_611465 != nil:
    section.add "Name", valid_611465
  var valid_611466 = query.getOrDefault("Action")
  valid_611466 = validateParameter(valid_611466, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_611466 != nil:
    section.add "Action", valid_611466
  var valid_611467 = query.getOrDefault("Version")
  valid_611467 = validateParameter(valid_611467, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611467 != nil:
    section.add "Version", valid_611467
  var valid_611468 = query.getOrDefault("Attributes.2.key")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "Attributes.2.key", valid_611468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611469 = header.getOrDefault("X-Amz-Signature")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Signature", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Content-Sha256", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Date")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Date", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Credential")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Credential", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Security-Token")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Security-Token", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Algorithm")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Algorithm", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-SignedHeaders", valid_611475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611476: Call_GetCreateTopic_611456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_611476.validator(path, query, header, formData, body)
  let scheme = call_611476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611476.url(scheme.get, call_611476.host, call_611476.base,
                         call_611476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611476, url, valid)

proc call*(call_611477: Call_GetCreateTopic_611456; Name: string;
          Attributes1Key: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Tags: JsonNode = nil;
          Attributes2Value: string = ""; Attributes1Value: string = "";
          Action: string = "CreateTopic"; Version: string = "2010-03-31";
          Attributes2Key: string = ""): Recallable =
  ## getCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Tags: JArray
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_611478 = newJObject()
  add(query_611478, "Attributes.1.key", newJString(Attributes1Key))
  add(query_611478, "Attributes.0.value", newJString(Attributes0Value))
  add(query_611478, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    query_611478.add "Tags", Tags
  add(query_611478, "Attributes.2.value", newJString(Attributes2Value))
  add(query_611478, "Attributes.1.value", newJString(Attributes1Value))
  add(query_611478, "Name", newJString(Name))
  add(query_611478, "Action", newJString(Action))
  add(query_611478, "Version", newJString(Version))
  add(query_611478, "Attributes.2.key", newJString(Attributes2Key))
  result = call_611477.call(nil, query_611478, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_611456(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_611457,
    base: "/", url: url_GetCreateTopic_611458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_611519 = ref object of OpenApiRestCall_610658
proc url_PostDeleteEndpoint_611521(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEndpoint_611520(path: JsonNode; query: JsonNode;
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
  var valid_611522 = query.getOrDefault("Action")
  valid_611522 = validateParameter(valid_611522, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_611522 != nil:
    section.add "Action", valid_611522
  var valid_611523 = query.getOrDefault("Version")
  valid_611523 = validateParameter(valid_611523, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611523 != nil:
    section.add "Version", valid_611523
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611524 = header.getOrDefault("X-Amz-Signature")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Signature", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Content-Sha256", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Date")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Date", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Credential")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Credential", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Security-Token")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Security-Token", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Algorithm")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Algorithm", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-SignedHeaders", valid_611530
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_611531 = formData.getOrDefault("EndpointArn")
  valid_611531 = validateParameter(valid_611531, JString, required = true,
                                 default = nil)
  if valid_611531 != nil:
    section.add "EndpointArn", valid_611531
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611532: Call_PostDeleteEndpoint_611519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_611532.validator(path, query, header, formData, body)
  let scheme = call_611532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611532.url(scheme.get, call_611532.host, call_611532.base,
                         call_611532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611532, url, valid)

proc call*(call_611533: Call_PostDeleteEndpoint_611519; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611534 = newJObject()
  var formData_611535 = newJObject()
  add(formData_611535, "EndpointArn", newJString(EndpointArn))
  add(query_611534, "Action", newJString(Action))
  add(query_611534, "Version", newJString(Version))
  result = call_611533.call(nil, query_611534, nil, formData_611535, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_611519(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_611520, base: "/",
    url: url_PostDeleteEndpoint_611521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_611503 = ref object of OpenApiRestCall_610658
proc url_GetDeleteEndpoint_611505(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEndpoint_611504(path: JsonNode; query: JsonNode;
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
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: JString (required)
  section = newJObject()
  var valid_611506 = query.getOrDefault("Action")
  valid_611506 = validateParameter(valid_611506, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_611506 != nil:
    section.add "Action", valid_611506
  var valid_611507 = query.getOrDefault("EndpointArn")
  valid_611507 = validateParameter(valid_611507, JString, required = true,
                                 default = nil)
  if valid_611507 != nil:
    section.add "EndpointArn", valid_611507
  var valid_611508 = query.getOrDefault("Version")
  valid_611508 = validateParameter(valid_611508, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611508 != nil:
    section.add "Version", valid_611508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611509 = header.getOrDefault("X-Amz-Signature")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Signature", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Content-Sha256", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Date")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Date", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Credential")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Credential", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Security-Token")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Security-Token", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Algorithm")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Algorithm", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-SignedHeaders", valid_611515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611516: Call_GetDeleteEndpoint_611503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_611516.validator(path, query, header, formData, body)
  let scheme = call_611516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611516.url(scheme.get, call_611516.host, call_611516.base,
                         call_611516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611516, url, valid)

proc call*(call_611517: Call_GetDeleteEndpoint_611503; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_611518 = newJObject()
  add(query_611518, "Action", newJString(Action))
  add(query_611518, "EndpointArn", newJString(EndpointArn))
  add(query_611518, "Version", newJString(Version))
  result = call_611517.call(nil, query_611518, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_611503(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_611504,
    base: "/", url: url_GetDeleteEndpoint_611505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_611552 = ref object of OpenApiRestCall_610658
proc url_PostDeletePlatformApplication_611554(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeletePlatformApplication_611553(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611555 = query.getOrDefault("Action")
  valid_611555 = validateParameter(valid_611555, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_611555 != nil:
    section.add "Action", valid_611555
  var valid_611556 = query.getOrDefault("Version")
  valid_611556 = validateParameter(valid_611556, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611556 != nil:
    section.add "Version", valid_611556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611557 = header.getOrDefault("X-Amz-Signature")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Signature", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Content-Sha256", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Date")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Date", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Credential")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Credential", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Security-Token")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Security-Token", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Algorithm")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Algorithm", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-SignedHeaders", valid_611563
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_611564 = formData.getOrDefault("PlatformApplicationArn")
  valid_611564 = validateParameter(valid_611564, JString, required = true,
                                 default = nil)
  if valid_611564 != nil:
    section.add "PlatformApplicationArn", valid_611564
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611565: Call_PostDeletePlatformApplication_611552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_611565.validator(path, query, header, formData, body)
  let scheme = call_611565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611565.url(scheme.get, call_611565.host, call_611565.base,
                         call_611565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611565, url, valid)

proc call*(call_611566: Call_PostDeletePlatformApplication_611552;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611567 = newJObject()
  var formData_611568 = newJObject()
  add(formData_611568, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_611567, "Action", newJString(Action))
  add(query_611567, "Version", newJString(Version))
  result = call_611566.call(nil, query_611567, nil, formData_611568, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_611552(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_611553, base: "/",
    url: url_PostDeletePlatformApplication_611554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_611536 = ref object of OpenApiRestCall_610658
proc url_GetDeletePlatformApplication_611538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeletePlatformApplication_611537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_611539 = query.getOrDefault("PlatformApplicationArn")
  valid_611539 = validateParameter(valid_611539, JString, required = true,
                                 default = nil)
  if valid_611539 != nil:
    section.add "PlatformApplicationArn", valid_611539
  var valid_611540 = query.getOrDefault("Action")
  valid_611540 = validateParameter(valid_611540, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_611540 != nil:
    section.add "Action", valid_611540
  var valid_611541 = query.getOrDefault("Version")
  valid_611541 = validateParameter(valid_611541, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611541 != nil:
    section.add "Version", valid_611541
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611542 = header.getOrDefault("X-Amz-Signature")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Signature", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Content-Sha256", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Date")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Date", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Credential")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Credential", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Security-Token")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Security-Token", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Algorithm")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Algorithm", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-SignedHeaders", valid_611548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611549: Call_GetDeletePlatformApplication_611536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_611549.validator(path, query, header, formData, body)
  let scheme = call_611549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611549.url(scheme.get, call_611549.host, call_611549.base,
                         call_611549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611549, url, valid)

proc call*(call_611550: Call_GetDeletePlatformApplication_611536;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611551 = newJObject()
  add(query_611551, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_611551, "Action", newJString(Action))
  add(query_611551, "Version", newJString(Version))
  result = call_611550.call(nil, query_611551, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_611536(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_611537, base: "/",
    url: url_GetDeletePlatformApplication_611538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_611585 = ref object of OpenApiRestCall_610658
proc url_PostDeleteTopic_611587(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteTopic_611586(path: JsonNode; query: JsonNode;
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
  var valid_611588 = query.getOrDefault("Action")
  valid_611588 = validateParameter(valid_611588, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_611588 != nil:
    section.add "Action", valid_611588
  var valid_611589 = query.getOrDefault("Version")
  valid_611589 = validateParameter(valid_611589, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611589 != nil:
    section.add "Version", valid_611589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611590 = header.getOrDefault("X-Amz-Signature")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Signature", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Content-Sha256", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Date")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Date", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Credential")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Credential", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Security-Token")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Security-Token", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Algorithm")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Algorithm", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-SignedHeaders", valid_611596
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_611597 = formData.getOrDefault("TopicArn")
  valid_611597 = validateParameter(valid_611597, JString, required = true,
                                 default = nil)
  if valid_611597 != nil:
    section.add "TopicArn", valid_611597
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611598: Call_PostDeleteTopic_611585; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_611598.validator(path, query, header, formData, body)
  let scheme = call_611598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611598.url(scheme.get, call_611598.host, call_611598.base,
                         call_611598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611598, url, valid)

proc call*(call_611599: Call_PostDeleteTopic_611585; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611600 = newJObject()
  var formData_611601 = newJObject()
  add(formData_611601, "TopicArn", newJString(TopicArn))
  add(query_611600, "Action", newJString(Action))
  add(query_611600, "Version", newJString(Version))
  result = call_611599.call(nil, query_611600, nil, formData_611601, nil)

var postDeleteTopic* = Call_PostDeleteTopic_611585(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_611586,
    base: "/", url: url_PostDeleteTopic_611587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_611569 = ref object of OpenApiRestCall_610658
proc url_GetDeleteTopic_611571(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteTopic_611570(path: JsonNode; query: JsonNode;
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
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  var valid_611572 = query.getOrDefault("Action")
  valid_611572 = validateParameter(valid_611572, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_611572 != nil:
    section.add "Action", valid_611572
  var valid_611573 = query.getOrDefault("Version")
  valid_611573 = validateParameter(valid_611573, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611573 != nil:
    section.add "Version", valid_611573
  var valid_611574 = query.getOrDefault("TopicArn")
  valid_611574 = validateParameter(valid_611574, JString, required = true,
                                 default = nil)
  if valid_611574 != nil:
    section.add "TopicArn", valid_611574
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611575 = header.getOrDefault("X-Amz-Signature")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Signature", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Content-Sha256", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Date")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Date", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Credential")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Credential", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Security-Token")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Security-Token", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Algorithm")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Algorithm", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-SignedHeaders", valid_611581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611582: Call_GetDeleteTopic_611569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_611582.validator(path, query, header, formData, body)
  let scheme = call_611582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611582.url(scheme.get, call_611582.host, call_611582.base,
                         call_611582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611582, url, valid)

proc call*(call_611583: Call_GetDeleteTopic_611569; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  var query_611584 = newJObject()
  add(query_611584, "Action", newJString(Action))
  add(query_611584, "Version", newJString(Version))
  add(query_611584, "TopicArn", newJString(TopicArn))
  result = call_611583.call(nil, query_611584, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_611569(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_611570,
    base: "/", url: url_GetDeleteTopic_611571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_611618 = ref object of OpenApiRestCall_610658
proc url_PostGetEndpointAttributes_611620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetEndpointAttributes_611619(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611621 = query.getOrDefault("Action")
  valid_611621 = validateParameter(valid_611621, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_611621 != nil:
    section.add "Action", valid_611621
  var valid_611622 = query.getOrDefault("Version")
  valid_611622 = validateParameter(valid_611622, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611622 != nil:
    section.add "Version", valid_611622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611623 = header.getOrDefault("X-Amz-Signature")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Signature", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Content-Sha256", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Date")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Date", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Credential")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Credential", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Security-Token")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Security-Token", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Algorithm")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Algorithm", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-SignedHeaders", valid_611629
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_611630 = formData.getOrDefault("EndpointArn")
  valid_611630 = validateParameter(valid_611630, JString, required = true,
                                 default = nil)
  if valid_611630 != nil:
    section.add "EndpointArn", valid_611630
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611631: Call_PostGetEndpointAttributes_611618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_611631.validator(path, query, header, formData, body)
  let scheme = call_611631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611631.url(scheme.get, call_611631.host, call_611631.base,
                         call_611631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611631, url, valid)

proc call*(call_611632: Call_PostGetEndpointAttributes_611618; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611633 = newJObject()
  var formData_611634 = newJObject()
  add(formData_611634, "EndpointArn", newJString(EndpointArn))
  add(query_611633, "Action", newJString(Action))
  add(query_611633, "Version", newJString(Version))
  result = call_611632.call(nil, query_611633, nil, formData_611634, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_611618(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_611619, base: "/",
    url: url_PostGetEndpointAttributes_611620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_611602 = ref object of OpenApiRestCall_610658
proc url_GetGetEndpointAttributes_611604(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetEndpointAttributes_611603(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: JString (required)
  section = newJObject()
  var valid_611605 = query.getOrDefault("Action")
  valid_611605 = validateParameter(valid_611605, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_611605 != nil:
    section.add "Action", valid_611605
  var valid_611606 = query.getOrDefault("EndpointArn")
  valid_611606 = validateParameter(valid_611606, JString, required = true,
                                 default = nil)
  if valid_611606 != nil:
    section.add "EndpointArn", valid_611606
  var valid_611607 = query.getOrDefault("Version")
  valid_611607 = validateParameter(valid_611607, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611607 != nil:
    section.add "Version", valid_611607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611608 = header.getOrDefault("X-Amz-Signature")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Signature", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Content-Sha256", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-Date")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Date", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-Credential")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Credential", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-Security-Token")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-Security-Token", valid_611612
  var valid_611613 = header.getOrDefault("X-Amz-Algorithm")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Algorithm", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-SignedHeaders", valid_611614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611615: Call_GetGetEndpointAttributes_611602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_611615.validator(path, query, header, formData, body)
  let scheme = call_611615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611615.url(scheme.get, call_611615.host, call_611615.base,
                         call_611615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611615, url, valid)

proc call*(call_611616: Call_GetGetEndpointAttributes_611602; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_611617 = newJObject()
  add(query_611617, "Action", newJString(Action))
  add(query_611617, "EndpointArn", newJString(EndpointArn))
  add(query_611617, "Version", newJString(Version))
  result = call_611616.call(nil, query_611617, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_611602(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_611603, base: "/",
    url: url_GetGetEndpointAttributes_611604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_611651 = ref object of OpenApiRestCall_610658
proc url_PostGetPlatformApplicationAttributes_611653(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetPlatformApplicationAttributes_611652(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611654 = query.getOrDefault("Action")
  valid_611654 = validateParameter(valid_611654, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_611654 != nil:
    section.add "Action", valid_611654
  var valid_611655 = query.getOrDefault("Version")
  valid_611655 = validateParameter(valid_611655, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611655 != nil:
    section.add "Version", valid_611655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611656 = header.getOrDefault("X-Amz-Signature")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Signature", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Content-Sha256", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-Date")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Date", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Credential")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Credential", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Security-Token")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Security-Token", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Algorithm")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Algorithm", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-SignedHeaders", valid_611662
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_611663 = formData.getOrDefault("PlatformApplicationArn")
  valid_611663 = validateParameter(valid_611663, JString, required = true,
                                 default = nil)
  if valid_611663 != nil:
    section.add "PlatformApplicationArn", valid_611663
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611664: Call_PostGetPlatformApplicationAttributes_611651;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_611664.validator(path, query, header, formData, body)
  let scheme = call_611664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611664.url(scheme.get, call_611664.host, call_611664.base,
                         call_611664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611664, url, valid)

proc call*(call_611665: Call_PostGetPlatformApplicationAttributes_611651;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611666 = newJObject()
  var formData_611667 = newJObject()
  add(formData_611667, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_611666, "Action", newJString(Action))
  add(query_611666, "Version", newJString(Version))
  result = call_611665.call(nil, query_611666, nil, formData_611667, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_611651(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_611652, base: "/",
    url: url_PostGetPlatformApplicationAttributes_611653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_611635 = ref object of OpenApiRestCall_610658
proc url_GetGetPlatformApplicationAttributes_611637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetPlatformApplicationAttributes_611636(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_611638 = query.getOrDefault("PlatformApplicationArn")
  valid_611638 = validateParameter(valid_611638, JString, required = true,
                                 default = nil)
  if valid_611638 != nil:
    section.add "PlatformApplicationArn", valid_611638
  var valid_611639 = query.getOrDefault("Action")
  valid_611639 = validateParameter(valid_611639, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_611639 != nil:
    section.add "Action", valid_611639
  var valid_611640 = query.getOrDefault("Version")
  valid_611640 = validateParameter(valid_611640, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611640 != nil:
    section.add "Version", valid_611640
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611641 = header.getOrDefault("X-Amz-Signature")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Signature", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-Content-Sha256", valid_611642
  var valid_611643 = header.getOrDefault("X-Amz-Date")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-Date", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Credential")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Credential", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Security-Token")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Security-Token", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Algorithm")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Algorithm", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-SignedHeaders", valid_611647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611648: Call_GetGetPlatformApplicationAttributes_611635;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_611648.validator(path, query, header, formData, body)
  let scheme = call_611648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611648.url(scheme.get, call_611648.host, call_611648.base,
                         call_611648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611648, url, valid)

proc call*(call_611649: Call_GetGetPlatformApplicationAttributes_611635;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611650 = newJObject()
  add(query_611650, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_611650, "Action", newJString(Action))
  add(query_611650, "Version", newJString(Version))
  result = call_611649.call(nil, query_611650, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_611635(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_611636, base: "/",
    url: url_GetGetPlatformApplicationAttributes_611637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_611684 = ref object of OpenApiRestCall_610658
proc url_PostGetSMSAttributes_611686(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetSMSAttributes_611685(path: JsonNode; query: JsonNode;
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
  var valid_611687 = query.getOrDefault("Action")
  valid_611687 = validateParameter(valid_611687, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_611687 != nil:
    section.add "Action", valid_611687
  var valid_611688 = query.getOrDefault("Version")
  valid_611688 = validateParameter(valid_611688, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611688 != nil:
    section.add "Version", valid_611688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611689 = header.getOrDefault("X-Amz-Signature")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Signature", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Content-Sha256", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Date")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Date", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Credential")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Credential", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Security-Token")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Security-Token", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Algorithm")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Algorithm", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-SignedHeaders", valid_611695
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_611696 = formData.getOrDefault("attributes")
  valid_611696 = validateParameter(valid_611696, JArray, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "attributes", valid_611696
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611697: Call_PostGetSMSAttributes_611684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_611697.validator(path, query, header, formData, body)
  let scheme = call_611697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611697.url(scheme.get, call_611697.host, call_611697.base,
                         call_611697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611697, url, valid)

proc call*(call_611698: Call_PostGetSMSAttributes_611684;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611699 = newJObject()
  var formData_611700 = newJObject()
  if attributes != nil:
    formData_611700.add "attributes", attributes
  add(query_611699, "Action", newJString(Action))
  add(query_611699, "Version", newJString(Version))
  result = call_611698.call(nil, query_611699, nil, formData_611700, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_611684(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_611685, base: "/",
    url: url_PostGetSMSAttributes_611686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_611668 = ref object of OpenApiRestCall_610658
proc url_GetGetSMSAttributes_611670(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetSMSAttributes_611669(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_611671 = query.getOrDefault("Action")
  valid_611671 = validateParameter(valid_611671, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_611671 != nil:
    section.add "Action", valid_611671
  var valid_611672 = query.getOrDefault("attributes")
  valid_611672 = validateParameter(valid_611672, JArray, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "attributes", valid_611672
  var valid_611673 = query.getOrDefault("Version")
  valid_611673 = validateParameter(valid_611673, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611673 != nil:
    section.add "Version", valid_611673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611674 = header.getOrDefault("X-Amz-Signature")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Signature", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Content-Sha256", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Date")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Date", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Credential")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Credential", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Security-Token")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Security-Token", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Algorithm")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Algorithm", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-SignedHeaders", valid_611680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611681: Call_GetGetSMSAttributes_611668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_611681.validator(path, query, header, formData, body)
  let scheme = call_611681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611681.url(scheme.get, call_611681.host, call_611681.base,
                         call_611681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611681, url, valid)

proc call*(call_611682: Call_GetGetSMSAttributes_611668;
          Action: string = "GetSMSAttributes"; attributes: JsonNode = nil;
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   Action: string (required)
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Version: string (required)
  var query_611683 = newJObject()
  add(query_611683, "Action", newJString(Action))
  if attributes != nil:
    query_611683.add "attributes", attributes
  add(query_611683, "Version", newJString(Version))
  result = call_611682.call(nil, query_611683, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_611668(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_611669, base: "/",
    url: url_GetGetSMSAttributes_611670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_611717 = ref object of OpenApiRestCall_610658
proc url_PostGetSubscriptionAttributes_611719(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetSubscriptionAttributes_611718(path: JsonNode; query: JsonNode;
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
  var valid_611720 = query.getOrDefault("Action")
  valid_611720 = validateParameter(valid_611720, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_611720 != nil:
    section.add "Action", valid_611720
  var valid_611721 = query.getOrDefault("Version")
  valid_611721 = validateParameter(valid_611721, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611721 != nil:
    section.add "Version", valid_611721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611722 = header.getOrDefault("X-Amz-Signature")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Signature", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Content-Sha256", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Date")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Date", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Credential")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Credential", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Security-Token")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Security-Token", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Algorithm")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Algorithm", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-SignedHeaders", valid_611728
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_611729 = formData.getOrDefault("SubscriptionArn")
  valid_611729 = validateParameter(valid_611729, JString, required = true,
                                 default = nil)
  if valid_611729 != nil:
    section.add "SubscriptionArn", valid_611729
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611730: Call_PostGetSubscriptionAttributes_611717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_611730.validator(path, query, header, formData, body)
  let scheme = call_611730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611730.url(scheme.get, call_611730.host, call_611730.base,
                         call_611730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611730, url, valid)

proc call*(call_611731: Call_PostGetSubscriptionAttributes_611717;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611732 = newJObject()
  var formData_611733 = newJObject()
  add(formData_611733, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_611732, "Action", newJString(Action))
  add(query_611732, "Version", newJString(Version))
  result = call_611731.call(nil, query_611732, nil, formData_611733, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_611717(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_611718, base: "/",
    url: url_PostGetSubscriptionAttributes_611719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_611701 = ref object of OpenApiRestCall_610658
proc url_GetGetSubscriptionAttributes_611703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetSubscriptionAttributes_611702(path: JsonNode; query: JsonNode;
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
  var valid_611704 = query.getOrDefault("SubscriptionArn")
  valid_611704 = validateParameter(valid_611704, JString, required = true,
                                 default = nil)
  if valid_611704 != nil:
    section.add "SubscriptionArn", valid_611704
  var valid_611705 = query.getOrDefault("Action")
  valid_611705 = validateParameter(valid_611705, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_611705 != nil:
    section.add "Action", valid_611705
  var valid_611706 = query.getOrDefault("Version")
  valid_611706 = validateParameter(valid_611706, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611706 != nil:
    section.add "Version", valid_611706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611707 = header.getOrDefault("X-Amz-Signature")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Signature", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Content-Sha256", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Date")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Date", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Credential")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Credential", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Security-Token")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Security-Token", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Algorithm")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Algorithm", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-SignedHeaders", valid_611713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611714: Call_GetGetSubscriptionAttributes_611701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_611714.validator(path, query, header, formData, body)
  let scheme = call_611714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611714.url(scheme.get, call_611714.host, call_611714.base,
                         call_611714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611714, url, valid)

proc call*(call_611715: Call_GetGetSubscriptionAttributes_611701;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611716 = newJObject()
  add(query_611716, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_611716, "Action", newJString(Action))
  add(query_611716, "Version", newJString(Version))
  result = call_611715.call(nil, query_611716, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_611701(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_611702, base: "/",
    url: url_GetGetSubscriptionAttributes_611703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_611750 = ref object of OpenApiRestCall_610658
proc url_PostGetTopicAttributes_611752(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetTopicAttributes_611751(path: JsonNode; query: JsonNode;
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
  var valid_611753 = query.getOrDefault("Action")
  valid_611753 = validateParameter(valid_611753, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_611753 != nil:
    section.add "Action", valid_611753
  var valid_611754 = query.getOrDefault("Version")
  valid_611754 = validateParameter(valid_611754, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611754 != nil:
    section.add "Version", valid_611754
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611755 = header.getOrDefault("X-Amz-Signature")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Signature", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Content-Sha256", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Date")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Date", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Credential")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Credential", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Security-Token")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Security-Token", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Algorithm")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Algorithm", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-SignedHeaders", valid_611761
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_611762 = formData.getOrDefault("TopicArn")
  valid_611762 = validateParameter(valid_611762, JString, required = true,
                                 default = nil)
  if valid_611762 != nil:
    section.add "TopicArn", valid_611762
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611763: Call_PostGetTopicAttributes_611750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_611763.validator(path, query, header, formData, body)
  let scheme = call_611763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611763.url(scheme.get, call_611763.host, call_611763.base,
                         call_611763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611763, url, valid)

proc call*(call_611764: Call_PostGetTopicAttributes_611750; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611765 = newJObject()
  var formData_611766 = newJObject()
  add(formData_611766, "TopicArn", newJString(TopicArn))
  add(query_611765, "Action", newJString(Action))
  add(query_611765, "Version", newJString(Version))
  result = call_611764.call(nil, query_611765, nil, formData_611766, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_611750(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_611751, base: "/",
    url: url_PostGetTopicAttributes_611752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_611734 = ref object of OpenApiRestCall_610658
proc url_GetGetTopicAttributes_611736(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetTopicAttributes_611735(path: JsonNode; query: JsonNode;
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
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  var valid_611737 = query.getOrDefault("Action")
  valid_611737 = validateParameter(valid_611737, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_611737 != nil:
    section.add "Action", valid_611737
  var valid_611738 = query.getOrDefault("Version")
  valid_611738 = validateParameter(valid_611738, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611738 != nil:
    section.add "Version", valid_611738
  var valid_611739 = query.getOrDefault("TopicArn")
  valid_611739 = validateParameter(valid_611739, JString, required = true,
                                 default = nil)
  if valid_611739 != nil:
    section.add "TopicArn", valid_611739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611740 = header.getOrDefault("X-Amz-Signature")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Signature", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Content-Sha256", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Date")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Date", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Credential")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Credential", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Security-Token")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Security-Token", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Algorithm")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Algorithm", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-SignedHeaders", valid_611746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611747: Call_GetGetTopicAttributes_611734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_611747.validator(path, query, header, formData, body)
  let scheme = call_611747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611747.url(scheme.get, call_611747.host, call_611747.base,
                         call_611747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611747, url, valid)

proc call*(call_611748: Call_GetGetTopicAttributes_611734; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  var query_611749 = newJObject()
  add(query_611749, "Action", newJString(Action))
  add(query_611749, "Version", newJString(Version))
  add(query_611749, "TopicArn", newJString(TopicArn))
  result = call_611748.call(nil, query_611749, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_611734(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_611735, base: "/",
    url: url_GetGetTopicAttributes_611736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_611784 = ref object of OpenApiRestCall_610658
proc url_PostListEndpointsByPlatformApplication_611786(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListEndpointsByPlatformApplication_611785(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611787 = query.getOrDefault("Action")
  valid_611787 = validateParameter(valid_611787, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_611787 != nil:
    section.add "Action", valid_611787
  var valid_611788 = query.getOrDefault("Version")
  valid_611788 = validateParameter(valid_611788, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611788 != nil:
    section.add "Version", valid_611788
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611789 = header.getOrDefault("X-Amz-Signature")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Signature", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Content-Sha256", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Date")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Date", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Credential")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Credential", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-Security-Token")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Security-Token", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Algorithm")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Algorithm", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-SignedHeaders", valid_611795
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_611796 = formData.getOrDefault("PlatformApplicationArn")
  valid_611796 = validateParameter(valid_611796, JString, required = true,
                                 default = nil)
  if valid_611796 != nil:
    section.add "PlatformApplicationArn", valid_611796
  var valid_611797 = formData.getOrDefault("NextToken")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "NextToken", valid_611797
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611798: Call_PostListEndpointsByPlatformApplication_611784;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_611798.validator(path, query, header, formData, body)
  let scheme = call_611798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611798.url(scheme.get, call_611798.host, call_611798.base,
                         call_611798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611798, url, valid)

proc call*(call_611799: Call_PostListEndpointsByPlatformApplication_611784;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611800 = newJObject()
  var formData_611801 = newJObject()
  add(formData_611801, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_611801, "NextToken", newJString(NextToken))
  add(query_611800, "Action", newJString(Action))
  add(query_611800, "Version", newJString(Version))
  result = call_611799.call(nil, query_611800, nil, formData_611801, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_611784(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_611785, base: "/",
    url: url_PostListEndpointsByPlatformApplication_611786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_611767 = ref object of OpenApiRestCall_610658
proc url_GetListEndpointsByPlatformApplication_611769(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListEndpointsByPlatformApplication_611768(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611770 = query.getOrDefault("NextToken")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "NextToken", valid_611770
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_611771 = query.getOrDefault("PlatformApplicationArn")
  valid_611771 = validateParameter(valid_611771, JString, required = true,
                                 default = nil)
  if valid_611771 != nil:
    section.add "PlatformApplicationArn", valid_611771
  var valid_611772 = query.getOrDefault("Action")
  valid_611772 = validateParameter(valid_611772, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_611772 != nil:
    section.add "Action", valid_611772
  var valid_611773 = query.getOrDefault("Version")
  valid_611773 = validateParameter(valid_611773, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611773 != nil:
    section.add "Version", valid_611773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611774 = header.getOrDefault("X-Amz-Signature")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Signature", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Content-Sha256", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-Date")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Date", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Credential")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Credential", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Security-Token")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Security-Token", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Algorithm")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Algorithm", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-SignedHeaders", valid_611780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611781: Call_GetListEndpointsByPlatformApplication_611767;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_611781.validator(path, query, header, formData, body)
  let scheme = call_611781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611781.url(scheme.get, call_611781.host, call_611781.base,
                         call_611781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611781, url, valid)

proc call*(call_611782: Call_GetListEndpointsByPlatformApplication_611767;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611783 = newJObject()
  add(query_611783, "NextToken", newJString(NextToken))
  add(query_611783, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_611783, "Action", newJString(Action))
  add(query_611783, "Version", newJString(Version))
  result = call_611782.call(nil, query_611783, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_611767(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_611768, base: "/",
    url: url_GetListEndpointsByPlatformApplication_611769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_611818 = ref object of OpenApiRestCall_610658
proc url_PostListPhoneNumbersOptedOut_611820(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListPhoneNumbersOptedOut_611819(path: JsonNode; query: JsonNode;
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
  var valid_611821 = query.getOrDefault("Action")
  valid_611821 = validateParameter(valid_611821, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_611821 != nil:
    section.add "Action", valid_611821
  var valid_611822 = query.getOrDefault("Version")
  valid_611822 = validateParameter(valid_611822, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611822 != nil:
    section.add "Version", valid_611822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611823 = header.getOrDefault("X-Amz-Signature")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "X-Amz-Signature", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Content-Sha256", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Date")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Date", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Credential")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Credential", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Security-Token")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Security-Token", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Algorithm")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Algorithm", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-SignedHeaders", valid_611829
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_611830 = formData.getOrDefault("nextToken")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "nextToken", valid_611830
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611831: Call_PostListPhoneNumbersOptedOut_611818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_611831.validator(path, query, header, formData, body)
  let scheme = call_611831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611831.url(scheme.get, call_611831.host, call_611831.base,
                         call_611831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611831, url, valid)

proc call*(call_611832: Call_PostListPhoneNumbersOptedOut_611818;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611833 = newJObject()
  var formData_611834 = newJObject()
  add(formData_611834, "nextToken", newJString(nextToken))
  add(query_611833, "Action", newJString(Action))
  add(query_611833, "Version", newJString(Version))
  result = call_611832.call(nil, query_611833, nil, formData_611834, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_611818(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_611819, base: "/",
    url: url_PostListPhoneNumbersOptedOut_611820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_611802 = ref object of OpenApiRestCall_610658
proc url_GetListPhoneNumbersOptedOut_611804(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListPhoneNumbersOptedOut_611803(path: JsonNode; query: JsonNode;
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
  var valid_611805 = query.getOrDefault("nextToken")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "nextToken", valid_611805
  var valid_611806 = query.getOrDefault("Action")
  valid_611806 = validateParameter(valid_611806, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_611806 != nil:
    section.add "Action", valid_611806
  var valid_611807 = query.getOrDefault("Version")
  valid_611807 = validateParameter(valid_611807, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611807 != nil:
    section.add "Version", valid_611807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611808 = header.getOrDefault("X-Amz-Signature")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Signature", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Content-Sha256", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Date")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Date", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Credential")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Credential", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Security-Token")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Security-Token", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Algorithm")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Algorithm", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-SignedHeaders", valid_611814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611815: Call_GetListPhoneNumbersOptedOut_611802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_611815.validator(path, query, header, formData, body)
  let scheme = call_611815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611815.url(scheme.get, call_611815.host, call_611815.base,
                         call_611815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611815, url, valid)

proc call*(call_611816: Call_GetListPhoneNumbersOptedOut_611802;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611817 = newJObject()
  add(query_611817, "nextToken", newJString(nextToken))
  add(query_611817, "Action", newJString(Action))
  add(query_611817, "Version", newJString(Version))
  result = call_611816.call(nil, query_611817, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_611802(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_611803, base: "/",
    url: url_GetListPhoneNumbersOptedOut_611804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_611851 = ref object of OpenApiRestCall_610658
proc url_PostListPlatformApplications_611853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListPlatformApplications_611852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611854 = query.getOrDefault("Action")
  valid_611854 = validateParameter(valid_611854, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_611854 != nil:
    section.add "Action", valid_611854
  var valid_611855 = query.getOrDefault("Version")
  valid_611855 = validateParameter(valid_611855, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611855 != nil:
    section.add "Version", valid_611855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611856 = header.getOrDefault("X-Amz-Signature")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Signature", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Content-Sha256", valid_611857
  var valid_611858 = header.getOrDefault("X-Amz-Date")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-Date", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Credential")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Credential", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-Security-Token")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-Security-Token", valid_611860
  var valid_611861 = header.getOrDefault("X-Amz-Algorithm")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "X-Amz-Algorithm", valid_611861
  var valid_611862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-SignedHeaders", valid_611862
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_611863 = formData.getOrDefault("NextToken")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "NextToken", valid_611863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611864: Call_PostListPlatformApplications_611851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_611864.validator(path, query, header, formData, body)
  let scheme = call_611864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611864.url(scheme.get, call_611864.host, call_611864.base,
                         call_611864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611864, url, valid)

proc call*(call_611865: Call_PostListPlatformApplications_611851;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611866 = newJObject()
  var formData_611867 = newJObject()
  add(formData_611867, "NextToken", newJString(NextToken))
  add(query_611866, "Action", newJString(Action))
  add(query_611866, "Version", newJString(Version))
  result = call_611865.call(nil, query_611866, nil, formData_611867, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_611851(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_611852, base: "/",
    url: url_PostListPlatformApplications_611853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_611835 = ref object of OpenApiRestCall_610658
proc url_GetListPlatformApplications_611837(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListPlatformApplications_611836(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
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
  var valid_611838 = query.getOrDefault("NextToken")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "NextToken", valid_611838
  var valid_611839 = query.getOrDefault("Action")
  valid_611839 = validateParameter(valid_611839, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_611839 != nil:
    section.add "Action", valid_611839
  var valid_611840 = query.getOrDefault("Version")
  valid_611840 = validateParameter(valid_611840, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611840 != nil:
    section.add "Version", valid_611840
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611841 = header.getOrDefault("X-Amz-Signature")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Signature", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Content-Sha256", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Date")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Date", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Credential")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Credential", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-Security-Token")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-Security-Token", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Algorithm")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Algorithm", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-SignedHeaders", valid_611847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611848: Call_GetListPlatformApplications_611835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_611848.validator(path, query, header, formData, body)
  let scheme = call_611848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611848.url(scheme.get, call_611848.host, call_611848.base,
                         call_611848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611848, url, valid)

proc call*(call_611849: Call_GetListPlatformApplications_611835;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611850 = newJObject()
  add(query_611850, "NextToken", newJString(NextToken))
  add(query_611850, "Action", newJString(Action))
  add(query_611850, "Version", newJString(Version))
  result = call_611849.call(nil, query_611850, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_611835(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_611836, base: "/",
    url: url_GetListPlatformApplications_611837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_611884 = ref object of OpenApiRestCall_610658
proc url_PostListSubscriptions_611886(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListSubscriptions_611885(path: JsonNode; query: JsonNode;
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
  var valid_611887 = query.getOrDefault("Action")
  valid_611887 = validateParameter(valid_611887, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_611887 != nil:
    section.add "Action", valid_611887
  var valid_611888 = query.getOrDefault("Version")
  valid_611888 = validateParameter(valid_611888, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611888 != nil:
    section.add "Version", valid_611888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611889 = header.getOrDefault("X-Amz-Signature")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Signature", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-Content-Sha256", valid_611890
  var valid_611891 = header.getOrDefault("X-Amz-Date")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "X-Amz-Date", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Credential")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Credential", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Security-Token")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Security-Token", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Algorithm")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Algorithm", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-SignedHeaders", valid_611895
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_611896 = formData.getOrDefault("NextToken")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "NextToken", valid_611896
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611897: Call_PostListSubscriptions_611884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_611897.validator(path, query, header, formData, body)
  let scheme = call_611897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611897.url(scheme.get, call_611897.host, call_611897.base,
                         call_611897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611897, url, valid)

proc call*(call_611898: Call_PostListSubscriptions_611884; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611899 = newJObject()
  var formData_611900 = newJObject()
  add(formData_611900, "NextToken", newJString(NextToken))
  add(query_611899, "Action", newJString(Action))
  add(query_611899, "Version", newJString(Version))
  result = call_611898.call(nil, query_611899, nil, formData_611900, nil)

var postListSubscriptions* = Call_PostListSubscriptions_611884(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_611885, base: "/",
    url: url_PostListSubscriptions_611886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_611868 = ref object of OpenApiRestCall_610658
proc url_GetListSubscriptions_611870(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListSubscriptions_611869(path: JsonNode; query: JsonNode;
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
  var valid_611871 = query.getOrDefault("NextToken")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "NextToken", valid_611871
  var valid_611872 = query.getOrDefault("Action")
  valid_611872 = validateParameter(valid_611872, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_611872 != nil:
    section.add "Action", valid_611872
  var valid_611873 = query.getOrDefault("Version")
  valid_611873 = validateParameter(valid_611873, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611873 != nil:
    section.add "Version", valid_611873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611874 = header.getOrDefault("X-Amz-Signature")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Signature", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-Content-Sha256", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Date")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Date", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Credential")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Credential", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Security-Token")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Security-Token", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Algorithm")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Algorithm", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-SignedHeaders", valid_611880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611881: Call_GetListSubscriptions_611868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_611881.validator(path, query, header, formData, body)
  let scheme = call_611881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611881.url(scheme.get, call_611881.host, call_611881.base,
                         call_611881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611881, url, valid)

proc call*(call_611882: Call_GetListSubscriptions_611868; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611883 = newJObject()
  add(query_611883, "NextToken", newJString(NextToken))
  add(query_611883, "Action", newJString(Action))
  add(query_611883, "Version", newJString(Version))
  result = call_611882.call(nil, query_611883, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_611868(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_611869, base: "/",
    url: url_GetListSubscriptions_611870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_611918 = ref object of OpenApiRestCall_610658
proc url_PostListSubscriptionsByTopic_611920(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListSubscriptionsByTopic_611919(path: JsonNode; query: JsonNode;
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
  var valid_611921 = query.getOrDefault("Action")
  valid_611921 = validateParameter(valid_611921, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_611921 != nil:
    section.add "Action", valid_611921
  var valid_611922 = query.getOrDefault("Version")
  valid_611922 = validateParameter(valid_611922, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611922 != nil:
    section.add "Version", valid_611922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611923 = header.getOrDefault("X-Amz-Signature")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-Signature", valid_611923
  var valid_611924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Content-Sha256", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Date")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Date", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Credential")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Credential", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Security-Token")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Security-Token", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Algorithm")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Algorithm", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-SignedHeaders", valid_611929
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_611930 = formData.getOrDefault("NextToken")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "NextToken", valid_611930
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_611931 = formData.getOrDefault("TopicArn")
  valid_611931 = validateParameter(valid_611931, JString, required = true,
                                 default = nil)
  if valid_611931 != nil:
    section.add "TopicArn", valid_611931
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611932: Call_PostListSubscriptionsByTopic_611918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_611932.validator(path, query, header, formData, body)
  let scheme = call_611932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611932.url(scheme.get, call_611932.host, call_611932.base,
                         call_611932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611932, url, valid)

proc call*(call_611933: Call_PostListSubscriptionsByTopic_611918; TopicArn: string;
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
  var query_611934 = newJObject()
  var formData_611935 = newJObject()
  add(formData_611935, "NextToken", newJString(NextToken))
  add(formData_611935, "TopicArn", newJString(TopicArn))
  add(query_611934, "Action", newJString(Action))
  add(query_611934, "Version", newJString(Version))
  result = call_611933.call(nil, query_611934, nil, formData_611935, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_611918(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_611919, base: "/",
    url: url_PostListSubscriptionsByTopic_611920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_611901 = ref object of OpenApiRestCall_610658
proc url_GetListSubscriptionsByTopic_611903(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListSubscriptionsByTopic_611902(path: JsonNode; query: JsonNode;
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
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_611904 = query.getOrDefault("NextToken")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "NextToken", valid_611904
  var valid_611905 = query.getOrDefault("Action")
  valid_611905 = validateParameter(valid_611905, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_611905 != nil:
    section.add "Action", valid_611905
  var valid_611906 = query.getOrDefault("Version")
  valid_611906 = validateParameter(valid_611906, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611906 != nil:
    section.add "Version", valid_611906
  var valid_611907 = query.getOrDefault("TopicArn")
  valid_611907 = validateParameter(valid_611907, JString, required = true,
                                 default = nil)
  if valid_611907 != nil:
    section.add "TopicArn", valid_611907
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611908 = header.getOrDefault("X-Amz-Signature")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "X-Amz-Signature", valid_611908
  var valid_611909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Content-Sha256", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Date")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Date", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Credential")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Credential", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Security-Token")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Security-Token", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Algorithm")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Algorithm", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-SignedHeaders", valid_611914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611915: Call_GetListSubscriptionsByTopic_611901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_611915.validator(path, query, header, formData, body)
  let scheme = call_611915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611915.url(scheme.get, call_611915.host, call_611915.base,
                         call_611915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611915, url, valid)

proc call*(call_611916: Call_GetListSubscriptionsByTopic_611901; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  var query_611917 = newJObject()
  add(query_611917, "NextToken", newJString(NextToken))
  add(query_611917, "Action", newJString(Action))
  add(query_611917, "Version", newJString(Version))
  add(query_611917, "TopicArn", newJString(TopicArn))
  result = call_611916.call(nil, query_611917, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_611901(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_611902, base: "/",
    url: url_GetListSubscriptionsByTopic_611903,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_611952 = ref object of OpenApiRestCall_610658
proc url_PostListTagsForResource_611954(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_611953(path: JsonNode; query: JsonNode;
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
  var valid_611955 = query.getOrDefault("Action")
  valid_611955 = validateParameter(valid_611955, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_611955 != nil:
    section.add "Action", valid_611955
  var valid_611956 = query.getOrDefault("Version")
  valid_611956 = validateParameter(valid_611956, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611956 != nil:
    section.add "Version", valid_611956
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611957 = header.getOrDefault("X-Amz-Signature")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-Signature", valid_611957
  var valid_611958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-Content-Sha256", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Date")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Date", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Credential")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Credential", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Security-Token")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Security-Token", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Algorithm")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Algorithm", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-SignedHeaders", valid_611963
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_611964 = formData.getOrDefault("ResourceArn")
  valid_611964 = validateParameter(valid_611964, JString, required = true,
                                 default = nil)
  if valid_611964 != nil:
    section.add "ResourceArn", valid_611964
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611965: Call_PostListTagsForResource_611952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_611965.validator(path, query, header, formData, body)
  let scheme = call_611965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611965.url(scheme.get, call_611965.host, call_611965.base,
                         call_611965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611965, url, valid)

proc call*(call_611966: Call_PostListTagsForResource_611952; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611967 = newJObject()
  var formData_611968 = newJObject()
  add(formData_611968, "ResourceArn", newJString(ResourceArn))
  add(query_611967, "Action", newJString(Action))
  add(query_611967, "Version", newJString(Version))
  result = call_611966.call(nil, query_611967, nil, formData_611968, nil)

var postListTagsForResource* = Call_PostListTagsForResource_611952(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_611953, base: "/",
    url: url_PostListTagsForResource_611954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_611936 = ref object of OpenApiRestCall_610658
proc url_GetListTagsForResource_611938(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_611937(path: JsonNode; query: JsonNode;
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
  var valid_611939 = query.getOrDefault("ResourceArn")
  valid_611939 = validateParameter(valid_611939, JString, required = true,
                                 default = nil)
  if valid_611939 != nil:
    section.add "ResourceArn", valid_611939
  var valid_611940 = query.getOrDefault("Action")
  valid_611940 = validateParameter(valid_611940, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_611940 != nil:
    section.add "Action", valid_611940
  var valid_611941 = query.getOrDefault("Version")
  valid_611941 = validateParameter(valid_611941, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611941 != nil:
    section.add "Version", valid_611941
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611942 = header.getOrDefault("X-Amz-Signature")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-Signature", valid_611942
  var valid_611943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-Content-Sha256", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Date")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Date", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Credential")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Credential", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Security-Token")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Security-Token", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Algorithm")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Algorithm", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-SignedHeaders", valid_611948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611949: Call_GetListTagsForResource_611936; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_611949.validator(path, query, header, formData, body)
  let scheme = call_611949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611949.url(scheme.get, call_611949.host, call_611949.base,
                         call_611949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611949, url, valid)

proc call*(call_611950: Call_GetListTagsForResource_611936; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611951 = newJObject()
  add(query_611951, "ResourceArn", newJString(ResourceArn))
  add(query_611951, "Action", newJString(Action))
  add(query_611951, "Version", newJString(Version))
  result = call_611950.call(nil, query_611951, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_611936(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_611937, base: "/",
    url: url_GetListTagsForResource_611938, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_611985 = ref object of OpenApiRestCall_610658
proc url_PostListTopics_611987(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTopics_611986(path: JsonNode; query: JsonNode;
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
  var valid_611988 = query.getOrDefault("Action")
  valid_611988 = validateParameter(valid_611988, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_611988 != nil:
    section.add "Action", valid_611988
  var valid_611989 = query.getOrDefault("Version")
  valid_611989 = validateParameter(valid_611989, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611989 != nil:
    section.add "Version", valid_611989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611990 = header.getOrDefault("X-Amz-Signature")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Signature", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Content-Sha256", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Date")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Date", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Credential")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Credential", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Security-Token")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Security-Token", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-Algorithm")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-Algorithm", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-SignedHeaders", valid_611996
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_611997 = formData.getOrDefault("NextToken")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "NextToken", valid_611997
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611998: Call_PostListTopics_611985; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_611998.validator(path, query, header, formData, body)
  let scheme = call_611998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611998.url(scheme.get, call_611998.host, call_611998.base,
                         call_611998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611998, url, valid)

proc call*(call_611999: Call_PostListTopics_611985; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612000 = newJObject()
  var formData_612001 = newJObject()
  add(formData_612001, "NextToken", newJString(NextToken))
  add(query_612000, "Action", newJString(Action))
  add(query_612000, "Version", newJString(Version))
  result = call_611999.call(nil, query_612000, nil, formData_612001, nil)

var postListTopics* = Call_PostListTopics_611985(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_611986,
    base: "/", url: url_PostListTopics_611987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_611969 = ref object of OpenApiRestCall_610658
proc url_GetListTopics_611971(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTopics_611970(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611972 = query.getOrDefault("NextToken")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "NextToken", valid_611972
  var valid_611973 = query.getOrDefault("Action")
  valid_611973 = validateParameter(valid_611973, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_611973 != nil:
    section.add "Action", valid_611973
  var valid_611974 = query.getOrDefault("Version")
  valid_611974 = validateParameter(valid_611974, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_611974 != nil:
    section.add "Version", valid_611974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611975 = header.getOrDefault("X-Amz-Signature")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Signature", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Content-Sha256", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Date")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Date", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Credential")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Credential", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-Security-Token")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-Security-Token", valid_611979
  var valid_611980 = header.getOrDefault("X-Amz-Algorithm")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-Algorithm", valid_611980
  var valid_611981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "X-Amz-SignedHeaders", valid_611981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611982: Call_GetListTopics_611969; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_611982.validator(path, query, header, formData, body)
  let scheme = call_611982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611982.url(scheme.get, call_611982.host, call_611982.base,
                         call_611982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611982, url, valid)

proc call*(call_611983: Call_GetListTopics_611969; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611984 = newJObject()
  add(query_611984, "NextToken", newJString(NextToken))
  add(query_611984, "Action", newJString(Action))
  add(query_611984, "Version", newJString(Version))
  result = call_611983.call(nil, query_611984, nil, nil, nil)

var getListTopics* = Call_GetListTopics_611969(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_611970,
    base: "/", url: url_GetListTopics_611971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_612018 = ref object of OpenApiRestCall_610658
proc url_PostOptInPhoneNumber_612020(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostOptInPhoneNumber_612019(path: JsonNode; query: JsonNode;
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
  var valid_612021 = query.getOrDefault("Action")
  valid_612021 = validateParameter(valid_612021, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_612021 != nil:
    section.add "Action", valid_612021
  var valid_612022 = query.getOrDefault("Version")
  valid_612022 = validateParameter(valid_612022, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612022 != nil:
    section.add "Version", valid_612022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612023 = header.getOrDefault("X-Amz-Signature")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Signature", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Content-Sha256", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Date")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Date", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Credential")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Credential", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Security-Token")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Security-Token", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-Algorithm")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Algorithm", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-SignedHeaders", valid_612029
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_612030 = formData.getOrDefault("phoneNumber")
  valid_612030 = validateParameter(valid_612030, JString, required = true,
                                 default = nil)
  if valid_612030 != nil:
    section.add "phoneNumber", valid_612030
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612031: Call_PostOptInPhoneNumber_612018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_612031.validator(path, query, header, formData, body)
  let scheme = call_612031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612031.url(scheme.get, call_612031.host, call_612031.base,
                         call_612031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612031, url, valid)

proc call*(call_612032: Call_PostOptInPhoneNumber_612018; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612033 = newJObject()
  var formData_612034 = newJObject()
  add(formData_612034, "phoneNumber", newJString(phoneNumber))
  add(query_612033, "Action", newJString(Action))
  add(query_612033, "Version", newJString(Version))
  result = call_612032.call(nil, query_612033, nil, formData_612034, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_612018(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_612019, base: "/",
    url: url_PostOptInPhoneNumber_612020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_612002 = ref object of OpenApiRestCall_610658
proc url_GetOptInPhoneNumber_612004(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOptInPhoneNumber_612003(path: JsonNode; query: JsonNode;
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
  var valid_612005 = query.getOrDefault("phoneNumber")
  valid_612005 = validateParameter(valid_612005, JString, required = true,
                                 default = nil)
  if valid_612005 != nil:
    section.add "phoneNumber", valid_612005
  var valid_612006 = query.getOrDefault("Action")
  valid_612006 = validateParameter(valid_612006, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_612006 != nil:
    section.add "Action", valid_612006
  var valid_612007 = query.getOrDefault("Version")
  valid_612007 = validateParameter(valid_612007, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612007 != nil:
    section.add "Version", valid_612007
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612008 = header.getOrDefault("X-Amz-Signature")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Signature", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Content-Sha256", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-Date")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Date", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-Credential")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Credential", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-Security-Token")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-Security-Token", valid_612012
  var valid_612013 = header.getOrDefault("X-Amz-Algorithm")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Algorithm", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-SignedHeaders", valid_612014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612015: Call_GetOptInPhoneNumber_612002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_612015.validator(path, query, header, formData, body)
  let scheme = call_612015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612015.url(scheme.get, call_612015.host, call_612015.base,
                         call_612015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612015, url, valid)

proc call*(call_612016: Call_GetOptInPhoneNumber_612002; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612017 = newJObject()
  add(query_612017, "phoneNumber", newJString(phoneNumber))
  add(query_612017, "Action", newJString(Action))
  add(query_612017, "Version", newJString(Version))
  result = call_612016.call(nil, query_612017, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_612002(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_612003, base: "/",
    url: url_GetOptInPhoneNumber_612004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_612062 = ref object of OpenApiRestCall_610658
proc url_PostPublish_612064(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPublish_612063(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612065 = query.getOrDefault("Action")
  valid_612065 = validateParameter(valid_612065, JString, required = true,
                                 default = newJString("Publish"))
  if valid_612065 != nil:
    section.add "Action", valid_612065
  var valid_612066 = query.getOrDefault("Version")
  valid_612066 = validateParameter(valid_612066, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612066 != nil:
    section.add "Version", valid_612066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612067 = header.getOrDefault("X-Amz-Signature")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Signature", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-Content-Sha256", valid_612068
  var valid_612069 = header.getOrDefault("X-Amz-Date")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-Date", valid_612069
  var valid_612070 = header.getOrDefault("X-Amz-Credential")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "X-Amz-Credential", valid_612070
  var valid_612071 = header.getOrDefault("X-Amz-Security-Token")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "X-Amz-Security-Token", valid_612071
  var valid_612072 = header.getOrDefault("X-Amz-Algorithm")
  valid_612072 = validateParameter(valid_612072, JString, required = false,
                                 default = nil)
  if valid_612072 != nil:
    section.add "X-Amz-Algorithm", valid_612072
  var valid_612073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612073 = validateParameter(valid_612073, JString, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "X-Amz-SignedHeaders", valid_612073
  result.add "header", section
  ## parameters in `formData` object:
  ##   MessageAttributes.1.key: JString
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes.2.value: JString
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.0.key: JString
  ##   MessageAttributes.2.key: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.1.value: JString
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  section = newJObject()
  var valid_612074 = formData.getOrDefault("MessageAttributes.1.key")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "MessageAttributes.1.key", valid_612074
  var valid_612075 = formData.getOrDefault("PhoneNumber")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "PhoneNumber", valid_612075
  var valid_612076 = formData.getOrDefault("MessageAttributes.2.value")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "MessageAttributes.2.value", valid_612076
  var valid_612077 = formData.getOrDefault("Subject")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "Subject", valid_612077
  var valid_612078 = formData.getOrDefault("MessageAttributes.0.value")
  valid_612078 = validateParameter(valid_612078, JString, required = false,
                                 default = nil)
  if valid_612078 != nil:
    section.add "MessageAttributes.0.value", valid_612078
  var valid_612079 = formData.getOrDefault("MessageAttributes.0.key")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "MessageAttributes.0.key", valid_612079
  var valid_612080 = formData.getOrDefault("MessageAttributes.2.key")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "MessageAttributes.2.key", valid_612080
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_612081 = formData.getOrDefault("Message")
  valid_612081 = validateParameter(valid_612081, JString, required = true,
                                 default = nil)
  if valid_612081 != nil:
    section.add "Message", valid_612081
  var valid_612082 = formData.getOrDefault("TopicArn")
  valid_612082 = validateParameter(valid_612082, JString, required = false,
                                 default = nil)
  if valid_612082 != nil:
    section.add "TopicArn", valid_612082
  var valid_612083 = formData.getOrDefault("MessageStructure")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "MessageStructure", valid_612083
  var valid_612084 = formData.getOrDefault("MessageAttributes.1.value")
  valid_612084 = validateParameter(valid_612084, JString, required = false,
                                 default = nil)
  if valid_612084 != nil:
    section.add "MessageAttributes.1.value", valid_612084
  var valid_612085 = formData.getOrDefault("TargetArn")
  valid_612085 = validateParameter(valid_612085, JString, required = false,
                                 default = nil)
  if valid_612085 != nil:
    section.add "TargetArn", valid_612085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612086: Call_PostPublish_612062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_612086.validator(path, query, header, formData, body)
  let scheme = call_612086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612086.url(scheme.get, call_612086.host, call_612086.base,
                         call_612086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612086, url, valid)

proc call*(call_612087: Call_PostPublish_612062; Message: string;
          MessageAttributes1Key: string = ""; PhoneNumber: string = "";
          MessageAttributes2Value: string = ""; Subject: string = "";
          MessageAttributes0Value: string = ""; MessageAttributes0Key: string = "";
          MessageAttributes2Key: string = ""; TopicArn: string = "";
          Action: string = "Publish"; MessageStructure: string = "";
          MessageAttributes1Value: string = ""; TargetArn: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   MessageAttributes1Key: string
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes2Value: string
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes0Key: string
  ##   MessageAttributes2Key: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   Action: string (required)
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes1Value: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: string (required)
  var query_612088 = newJObject()
  var formData_612089 = newJObject()
  add(formData_612089, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_612089, "PhoneNumber", newJString(PhoneNumber))
  add(formData_612089, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(formData_612089, "Subject", newJString(Subject))
  add(formData_612089, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_612089, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_612089, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(formData_612089, "Message", newJString(Message))
  add(formData_612089, "TopicArn", newJString(TopicArn))
  add(query_612088, "Action", newJString(Action))
  add(formData_612089, "MessageStructure", newJString(MessageStructure))
  add(formData_612089, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_612089, "TargetArn", newJString(TargetArn))
  add(query_612088, "Version", newJString(Version))
  result = call_612087.call(nil, query_612088, nil, formData_612089, nil)

var postPublish* = Call_PostPublish_612062(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_612063,
                                        base: "/", url: url_PostPublish_612064,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_612035 = ref object of OpenApiRestCall_610658
proc url_GetPublish_612037(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublish_612036(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.2.key: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageAttributes.2.value: JString
  ##   Action: JString (required)
  ##   MessageAttributes.1.key: JString
  ##   MessageAttributes.0.key: JString
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes.1.value: JString
  ##   Version: JString (required)
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  section = newJObject()
  var valid_612038 = query.getOrDefault("PhoneNumber")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "PhoneNumber", valid_612038
  var valid_612039 = query.getOrDefault("MessageStructure")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "MessageStructure", valid_612039
  var valid_612040 = query.getOrDefault("MessageAttributes.0.value")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "MessageAttributes.0.value", valid_612040
  var valid_612041 = query.getOrDefault("MessageAttributes.2.key")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "MessageAttributes.2.key", valid_612041
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_612042 = query.getOrDefault("Message")
  valid_612042 = validateParameter(valid_612042, JString, required = true,
                                 default = nil)
  if valid_612042 != nil:
    section.add "Message", valid_612042
  var valid_612043 = query.getOrDefault("MessageAttributes.2.value")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "MessageAttributes.2.value", valid_612043
  var valid_612044 = query.getOrDefault("Action")
  valid_612044 = validateParameter(valid_612044, JString, required = true,
                                 default = newJString("Publish"))
  if valid_612044 != nil:
    section.add "Action", valid_612044
  var valid_612045 = query.getOrDefault("MessageAttributes.1.key")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "MessageAttributes.1.key", valid_612045
  var valid_612046 = query.getOrDefault("MessageAttributes.0.key")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "MessageAttributes.0.key", valid_612046
  var valid_612047 = query.getOrDefault("Subject")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "Subject", valid_612047
  var valid_612048 = query.getOrDefault("MessageAttributes.1.value")
  valid_612048 = validateParameter(valid_612048, JString, required = false,
                                 default = nil)
  if valid_612048 != nil:
    section.add "MessageAttributes.1.value", valid_612048
  var valid_612049 = query.getOrDefault("Version")
  valid_612049 = validateParameter(valid_612049, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612049 != nil:
    section.add "Version", valid_612049
  var valid_612050 = query.getOrDefault("TargetArn")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "TargetArn", valid_612050
  var valid_612051 = query.getOrDefault("TopicArn")
  valid_612051 = validateParameter(valid_612051, JString, required = false,
                                 default = nil)
  if valid_612051 != nil:
    section.add "TopicArn", valid_612051
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612052 = header.getOrDefault("X-Amz-Signature")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-Signature", valid_612052
  var valid_612053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "X-Amz-Content-Sha256", valid_612053
  var valid_612054 = header.getOrDefault("X-Amz-Date")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-Date", valid_612054
  var valid_612055 = header.getOrDefault("X-Amz-Credential")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-Credential", valid_612055
  var valid_612056 = header.getOrDefault("X-Amz-Security-Token")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-Security-Token", valid_612056
  var valid_612057 = header.getOrDefault("X-Amz-Algorithm")
  valid_612057 = validateParameter(valid_612057, JString, required = false,
                                 default = nil)
  if valid_612057 != nil:
    section.add "X-Amz-Algorithm", valid_612057
  var valid_612058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-SignedHeaders", valid_612058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612059: Call_GetPublish_612035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_612059.validator(path, query, header, formData, body)
  let scheme = call_612059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612059.url(scheme.get, call_612059.host, call_612059.base,
                         call_612059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612059, url, valid)

proc call*(call_612060: Call_GetPublish_612035; Message: string;
          PhoneNumber: string = ""; MessageStructure: string = "";
          MessageAttributes0Value: string = ""; MessageAttributes2Key: string = "";
          MessageAttributes2Value: string = ""; Action: string = "Publish";
          MessageAttributes1Key: string = ""; MessageAttributes0Key: string = "";
          Subject: string = ""; MessageAttributes1Value: string = "";
          Version: string = "2010-03-31"; TargetArn: string = ""; TopicArn: string = ""): Recallable =
  ## getPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes2Key: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageAttributes2Value: string
  ##   Action: string (required)
  ##   MessageAttributes1Key: string
  ##   MessageAttributes0Key: string
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes1Value: string
  ##   Version: string (required)
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  var query_612061 = newJObject()
  add(query_612061, "PhoneNumber", newJString(PhoneNumber))
  add(query_612061, "MessageStructure", newJString(MessageStructure))
  add(query_612061, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_612061, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_612061, "Message", newJString(Message))
  add(query_612061, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_612061, "Action", newJString(Action))
  add(query_612061, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_612061, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_612061, "Subject", newJString(Subject))
  add(query_612061, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_612061, "Version", newJString(Version))
  add(query_612061, "TargetArn", newJString(TargetArn))
  add(query_612061, "TopicArn", newJString(TopicArn))
  result = call_612060.call(nil, query_612061, nil, nil, nil)

var getPublish* = Call_GetPublish_612035(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_612036,
                                      base: "/", url: url_GetPublish_612037,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_612107 = ref object of OpenApiRestCall_610658
proc url_PostRemovePermission_612109(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemovePermission_612108(path: JsonNode; query: JsonNode;
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
  var valid_612110 = query.getOrDefault("Action")
  valid_612110 = validateParameter(valid_612110, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_612110 != nil:
    section.add "Action", valid_612110
  var valid_612111 = query.getOrDefault("Version")
  valid_612111 = validateParameter(valid_612111, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612111 != nil:
    section.add "Version", valid_612111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612112 = header.getOrDefault("X-Amz-Signature")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "X-Amz-Signature", valid_612112
  var valid_612113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "X-Amz-Content-Sha256", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Date")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Date", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-Credential")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-Credential", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Security-Token")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Security-Token", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-Algorithm")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-Algorithm", valid_612117
  var valid_612118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "X-Amz-SignedHeaders", valid_612118
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_612119 = formData.getOrDefault("TopicArn")
  valid_612119 = validateParameter(valid_612119, JString, required = true,
                                 default = nil)
  if valid_612119 != nil:
    section.add "TopicArn", valid_612119
  var valid_612120 = formData.getOrDefault("Label")
  valid_612120 = validateParameter(valid_612120, JString, required = true,
                                 default = nil)
  if valid_612120 != nil:
    section.add "Label", valid_612120
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612121: Call_PostRemovePermission_612107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_612121.validator(path, query, header, formData, body)
  let scheme = call_612121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612121.url(scheme.get, call_612121.host, call_612121.base,
                         call_612121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612121, url, valid)

proc call*(call_612122: Call_PostRemovePermission_612107; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## postRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  ##   Version: string (required)
  var query_612123 = newJObject()
  var formData_612124 = newJObject()
  add(formData_612124, "TopicArn", newJString(TopicArn))
  add(query_612123, "Action", newJString(Action))
  add(formData_612124, "Label", newJString(Label))
  add(query_612123, "Version", newJString(Version))
  result = call_612122.call(nil, query_612123, nil, formData_612124, nil)

var postRemovePermission* = Call_PostRemovePermission_612107(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_612108, base: "/",
    url: url_PostRemovePermission_612109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_612090 = ref object of OpenApiRestCall_610658
proc url_GetRemovePermission_612092(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemovePermission_612091(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TopicArn` field"
  var valid_612093 = query.getOrDefault("TopicArn")
  valid_612093 = validateParameter(valid_612093, JString, required = true,
                                 default = nil)
  if valid_612093 != nil:
    section.add "TopicArn", valid_612093
  var valid_612094 = query.getOrDefault("Action")
  valid_612094 = validateParameter(valid_612094, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_612094 != nil:
    section.add "Action", valid_612094
  var valid_612095 = query.getOrDefault("Version")
  valid_612095 = validateParameter(valid_612095, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612095 != nil:
    section.add "Version", valid_612095
  var valid_612096 = query.getOrDefault("Label")
  valid_612096 = validateParameter(valid_612096, JString, required = true,
                                 default = nil)
  if valid_612096 != nil:
    section.add "Label", valid_612096
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612097 = header.getOrDefault("X-Amz-Signature")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-Signature", valid_612097
  var valid_612098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612098 = validateParameter(valid_612098, JString, required = false,
                                 default = nil)
  if valid_612098 != nil:
    section.add "X-Amz-Content-Sha256", valid_612098
  var valid_612099 = header.getOrDefault("X-Amz-Date")
  valid_612099 = validateParameter(valid_612099, JString, required = false,
                                 default = nil)
  if valid_612099 != nil:
    section.add "X-Amz-Date", valid_612099
  var valid_612100 = header.getOrDefault("X-Amz-Credential")
  valid_612100 = validateParameter(valid_612100, JString, required = false,
                                 default = nil)
  if valid_612100 != nil:
    section.add "X-Amz-Credential", valid_612100
  var valid_612101 = header.getOrDefault("X-Amz-Security-Token")
  valid_612101 = validateParameter(valid_612101, JString, required = false,
                                 default = nil)
  if valid_612101 != nil:
    section.add "X-Amz-Security-Token", valid_612101
  var valid_612102 = header.getOrDefault("X-Amz-Algorithm")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Algorithm", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-SignedHeaders", valid_612103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612104: Call_GetRemovePermission_612090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_612104.validator(path, query, header, formData, body)
  let scheme = call_612104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612104.url(scheme.get, call_612104.host, call_612104.base,
                         call_612104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612104, url, valid)

proc call*(call_612105: Call_GetRemovePermission_612090; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## getRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  var query_612106 = newJObject()
  add(query_612106, "TopicArn", newJString(TopicArn))
  add(query_612106, "Action", newJString(Action))
  add(query_612106, "Version", newJString(Version))
  add(query_612106, "Label", newJString(Label))
  result = call_612105.call(nil, query_612106, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_612090(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_612091, base: "/",
    url: url_GetRemovePermission_612092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_612147 = ref object of OpenApiRestCall_610658
proc url_PostSetEndpointAttributes_612149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetEndpointAttributes_612148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612150 = query.getOrDefault("Action")
  valid_612150 = validateParameter(valid_612150, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_612150 != nil:
    section.add "Action", valid_612150
  var valid_612151 = query.getOrDefault("Version")
  valid_612151 = validateParameter(valid_612151, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612151 != nil:
    section.add "Version", valid_612151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612152 = header.getOrDefault("X-Amz-Signature")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-Signature", valid_612152
  var valid_612153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "X-Amz-Content-Sha256", valid_612153
  var valid_612154 = header.getOrDefault("X-Amz-Date")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-Date", valid_612154
  var valid_612155 = header.getOrDefault("X-Amz-Credential")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "X-Amz-Credential", valid_612155
  var valid_612156 = header.getOrDefault("X-Amz-Security-Token")
  valid_612156 = validateParameter(valid_612156, JString, required = false,
                                 default = nil)
  if valid_612156 != nil:
    section.add "X-Amz-Security-Token", valid_612156
  var valid_612157 = header.getOrDefault("X-Amz-Algorithm")
  valid_612157 = validateParameter(valid_612157, JString, required = false,
                                 default = nil)
  if valid_612157 != nil:
    section.add "X-Amz-Algorithm", valid_612157
  var valid_612158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612158 = validateParameter(valid_612158, JString, required = false,
                                 default = nil)
  if valid_612158 != nil:
    section.add "X-Amz-SignedHeaders", valid_612158
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.key: JString
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_612159 = formData.getOrDefault("Attributes.0.key")
  valid_612159 = validateParameter(valid_612159, JString, required = false,
                                 default = nil)
  if valid_612159 != nil:
    section.add "Attributes.0.key", valid_612159
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_612160 = formData.getOrDefault("EndpointArn")
  valid_612160 = validateParameter(valid_612160, JString, required = true,
                                 default = nil)
  if valid_612160 != nil:
    section.add "EndpointArn", valid_612160
  var valid_612161 = formData.getOrDefault("Attributes.2.value")
  valid_612161 = validateParameter(valid_612161, JString, required = false,
                                 default = nil)
  if valid_612161 != nil:
    section.add "Attributes.2.value", valid_612161
  var valid_612162 = formData.getOrDefault("Attributes.2.key")
  valid_612162 = validateParameter(valid_612162, JString, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "Attributes.2.key", valid_612162
  var valid_612163 = formData.getOrDefault("Attributes.0.value")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "Attributes.0.value", valid_612163
  var valid_612164 = formData.getOrDefault("Attributes.1.key")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "Attributes.1.key", valid_612164
  var valid_612165 = formData.getOrDefault("Attributes.1.value")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "Attributes.1.value", valid_612165
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612166: Call_PostSetEndpointAttributes_612147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_612166.validator(path, query, header, formData, body)
  let scheme = call_612166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612166.url(scheme.get, call_612166.host, call_612166.base,
                         call_612166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612166, url, valid)

proc call*(call_612167: Call_PostSetEndpointAttributes_612147; EndpointArn: string;
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Attributes0Value: string = "";
          Attributes1Key: string = ""; Action: string = "SetEndpointAttributes";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Attributes0Key: string
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_612168 = newJObject()
  var formData_612169 = newJObject()
  add(formData_612169, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_612169, "EndpointArn", newJString(EndpointArn))
  add(formData_612169, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_612169, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_612169, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_612169, "Attributes.1.key", newJString(Attributes1Key))
  add(query_612168, "Action", newJString(Action))
  add(query_612168, "Version", newJString(Version))
  add(formData_612169, "Attributes.1.value", newJString(Attributes1Value))
  result = call_612167.call(nil, query_612168, nil, formData_612169, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_612147(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_612148, base: "/",
    url: url_PostSetEndpointAttributes_612149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_612125 = ref object of OpenApiRestCall_610658
proc url_GetSetEndpointAttributes_612127(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetEndpointAttributes_612126(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Action: JString (required)
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_612128 = query.getOrDefault("Attributes.1.key")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "Attributes.1.key", valid_612128
  var valid_612129 = query.getOrDefault("Attributes.0.value")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "Attributes.0.value", valid_612129
  var valid_612130 = query.getOrDefault("Attributes.0.key")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "Attributes.0.key", valid_612130
  var valid_612131 = query.getOrDefault("Attributes.2.value")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "Attributes.2.value", valid_612131
  var valid_612132 = query.getOrDefault("Attributes.1.value")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "Attributes.1.value", valid_612132
  var valid_612133 = query.getOrDefault("Action")
  valid_612133 = validateParameter(valid_612133, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_612133 != nil:
    section.add "Action", valid_612133
  var valid_612134 = query.getOrDefault("EndpointArn")
  valid_612134 = validateParameter(valid_612134, JString, required = true,
                                 default = nil)
  if valid_612134 != nil:
    section.add "EndpointArn", valid_612134
  var valid_612135 = query.getOrDefault("Version")
  valid_612135 = validateParameter(valid_612135, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612135 != nil:
    section.add "Version", valid_612135
  var valid_612136 = query.getOrDefault("Attributes.2.key")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "Attributes.2.key", valid_612136
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612137 = header.getOrDefault("X-Amz-Signature")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-Signature", valid_612137
  var valid_612138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612138 = validateParameter(valid_612138, JString, required = false,
                                 default = nil)
  if valid_612138 != nil:
    section.add "X-Amz-Content-Sha256", valid_612138
  var valid_612139 = header.getOrDefault("X-Amz-Date")
  valid_612139 = validateParameter(valid_612139, JString, required = false,
                                 default = nil)
  if valid_612139 != nil:
    section.add "X-Amz-Date", valid_612139
  var valid_612140 = header.getOrDefault("X-Amz-Credential")
  valid_612140 = validateParameter(valid_612140, JString, required = false,
                                 default = nil)
  if valid_612140 != nil:
    section.add "X-Amz-Credential", valid_612140
  var valid_612141 = header.getOrDefault("X-Amz-Security-Token")
  valid_612141 = validateParameter(valid_612141, JString, required = false,
                                 default = nil)
  if valid_612141 != nil:
    section.add "X-Amz-Security-Token", valid_612141
  var valid_612142 = header.getOrDefault("X-Amz-Algorithm")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-Algorithm", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-SignedHeaders", valid_612143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612144: Call_GetSetEndpointAttributes_612125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_612144.validator(path, query, header, formData, body)
  let scheme = call_612144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612144.url(scheme.get, call_612144.host, call_612144.base,
                         call_612144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612144, url, valid)

proc call*(call_612145: Call_GetSetEndpointAttributes_612125; EndpointArn: string;
          Attributes1Key: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes1Value: string = ""; Action: string = "SetEndpointAttributes";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_612146 = newJObject()
  add(query_612146, "Attributes.1.key", newJString(Attributes1Key))
  add(query_612146, "Attributes.0.value", newJString(Attributes0Value))
  add(query_612146, "Attributes.0.key", newJString(Attributes0Key))
  add(query_612146, "Attributes.2.value", newJString(Attributes2Value))
  add(query_612146, "Attributes.1.value", newJString(Attributes1Value))
  add(query_612146, "Action", newJString(Action))
  add(query_612146, "EndpointArn", newJString(EndpointArn))
  add(query_612146, "Version", newJString(Version))
  add(query_612146, "Attributes.2.key", newJString(Attributes2Key))
  result = call_612145.call(nil, query_612146, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_612125(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_612126, base: "/",
    url: url_GetSetEndpointAttributes_612127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_612192 = ref object of OpenApiRestCall_610658
proc url_PostSetPlatformApplicationAttributes_612194(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetPlatformApplicationAttributes_612193(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612195 = query.getOrDefault("Action")
  valid_612195 = validateParameter(valid_612195, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_612195 != nil:
    section.add "Action", valid_612195
  var valid_612196 = query.getOrDefault("Version")
  valid_612196 = validateParameter(valid_612196, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612196 != nil:
    section.add "Version", valid_612196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612197 = header.getOrDefault("X-Amz-Signature")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-Signature", valid_612197
  var valid_612198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "X-Amz-Content-Sha256", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-Date")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Date", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-Credential")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-Credential", valid_612200
  var valid_612201 = header.getOrDefault("X-Amz-Security-Token")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "X-Amz-Security-Token", valid_612201
  var valid_612202 = header.getOrDefault("X-Amz-Algorithm")
  valid_612202 = validateParameter(valid_612202, JString, required = false,
                                 default = nil)
  if valid_612202 != nil:
    section.add "X-Amz-Algorithm", valid_612202
  var valid_612203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612203 = validateParameter(valid_612203, JString, required = false,
                                 default = nil)
  if valid_612203 != nil:
    section.add "X-Amz-SignedHeaders", valid_612203
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_612204 = formData.getOrDefault("PlatformApplicationArn")
  valid_612204 = validateParameter(valid_612204, JString, required = true,
                                 default = nil)
  if valid_612204 != nil:
    section.add "PlatformApplicationArn", valid_612204
  var valid_612205 = formData.getOrDefault("Attributes.0.key")
  valid_612205 = validateParameter(valid_612205, JString, required = false,
                                 default = nil)
  if valid_612205 != nil:
    section.add "Attributes.0.key", valid_612205
  var valid_612206 = formData.getOrDefault("Attributes.2.value")
  valid_612206 = validateParameter(valid_612206, JString, required = false,
                                 default = nil)
  if valid_612206 != nil:
    section.add "Attributes.2.value", valid_612206
  var valid_612207 = formData.getOrDefault("Attributes.2.key")
  valid_612207 = validateParameter(valid_612207, JString, required = false,
                                 default = nil)
  if valid_612207 != nil:
    section.add "Attributes.2.key", valid_612207
  var valid_612208 = formData.getOrDefault("Attributes.0.value")
  valid_612208 = validateParameter(valid_612208, JString, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "Attributes.0.value", valid_612208
  var valid_612209 = formData.getOrDefault("Attributes.1.key")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "Attributes.1.key", valid_612209
  var valid_612210 = formData.getOrDefault("Attributes.1.value")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "Attributes.1.value", valid_612210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612211: Call_PostSetPlatformApplicationAttributes_612192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_612211.validator(path, query, header, formData, body)
  let scheme = call_612211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612211.url(scheme.get, call_612211.host, call_612211.base,
                         call_612211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612211, url, valid)

proc call*(call_612212: Call_PostSetPlatformApplicationAttributes_612192;
          PlatformApplicationArn: string; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_612213 = newJObject()
  var formData_612214 = newJObject()
  add(formData_612214, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_612214, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_612214, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_612214, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_612214, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_612214, "Attributes.1.key", newJString(Attributes1Key))
  add(query_612213, "Action", newJString(Action))
  add(query_612213, "Version", newJString(Version))
  add(formData_612214, "Attributes.1.value", newJString(Attributes1Value))
  result = call_612212.call(nil, query_612213, nil, formData_612214, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_612192(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_612193, base: "/",
    url: url_PostSetPlatformApplicationAttributes_612194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_612170 = ref object of OpenApiRestCall_610658
proc url_GetSetPlatformApplicationAttributes_612172(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetPlatformApplicationAttributes_612171(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_612173 = query.getOrDefault("Attributes.1.key")
  valid_612173 = validateParameter(valid_612173, JString, required = false,
                                 default = nil)
  if valid_612173 != nil:
    section.add "Attributes.1.key", valid_612173
  var valid_612174 = query.getOrDefault("Attributes.0.value")
  valid_612174 = validateParameter(valid_612174, JString, required = false,
                                 default = nil)
  if valid_612174 != nil:
    section.add "Attributes.0.value", valid_612174
  var valid_612175 = query.getOrDefault("Attributes.0.key")
  valid_612175 = validateParameter(valid_612175, JString, required = false,
                                 default = nil)
  if valid_612175 != nil:
    section.add "Attributes.0.key", valid_612175
  var valid_612176 = query.getOrDefault("Attributes.2.value")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "Attributes.2.value", valid_612176
  var valid_612177 = query.getOrDefault("Attributes.1.value")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "Attributes.1.value", valid_612177
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_612178 = query.getOrDefault("PlatformApplicationArn")
  valid_612178 = validateParameter(valid_612178, JString, required = true,
                                 default = nil)
  if valid_612178 != nil:
    section.add "PlatformApplicationArn", valid_612178
  var valid_612179 = query.getOrDefault("Action")
  valid_612179 = validateParameter(valid_612179, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_612179 != nil:
    section.add "Action", valid_612179
  var valid_612180 = query.getOrDefault("Version")
  valid_612180 = validateParameter(valid_612180, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612180 != nil:
    section.add "Version", valid_612180
  var valid_612181 = query.getOrDefault("Attributes.2.key")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "Attributes.2.key", valid_612181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612182 = header.getOrDefault("X-Amz-Signature")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Signature", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Content-Sha256", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-Date")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-Date", valid_612184
  var valid_612185 = header.getOrDefault("X-Amz-Credential")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "X-Amz-Credential", valid_612185
  var valid_612186 = header.getOrDefault("X-Amz-Security-Token")
  valid_612186 = validateParameter(valid_612186, JString, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "X-Amz-Security-Token", valid_612186
  var valid_612187 = header.getOrDefault("X-Amz-Algorithm")
  valid_612187 = validateParameter(valid_612187, JString, required = false,
                                 default = nil)
  if valid_612187 != nil:
    section.add "X-Amz-Algorithm", valid_612187
  var valid_612188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612188 = validateParameter(valid_612188, JString, required = false,
                                 default = nil)
  if valid_612188 != nil:
    section.add "X-Amz-SignedHeaders", valid_612188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612189: Call_GetSetPlatformApplicationAttributes_612170;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_612189.validator(path, query, header, formData, body)
  let scheme = call_612189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612189.url(scheme.get, call_612189.host, call_612189.base,
                         call_612189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612189, url, valid)

proc call*(call_612190: Call_GetSetPlatformApplicationAttributes_612170;
          PlatformApplicationArn: string; Attributes1Key: string = "";
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes1Value: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_612191 = newJObject()
  add(query_612191, "Attributes.1.key", newJString(Attributes1Key))
  add(query_612191, "Attributes.0.value", newJString(Attributes0Value))
  add(query_612191, "Attributes.0.key", newJString(Attributes0Key))
  add(query_612191, "Attributes.2.value", newJString(Attributes2Value))
  add(query_612191, "Attributes.1.value", newJString(Attributes1Value))
  add(query_612191, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_612191, "Action", newJString(Action))
  add(query_612191, "Version", newJString(Version))
  add(query_612191, "Attributes.2.key", newJString(Attributes2Key))
  result = call_612190.call(nil, query_612191, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_612170(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_612171, base: "/",
    url: url_GetSetPlatformApplicationAttributes_612172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_612236 = ref object of OpenApiRestCall_610658
proc url_PostSetSMSAttributes_612238(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSMSAttributes_612237(path: JsonNode; query: JsonNode;
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
  var valid_612239 = query.getOrDefault("Action")
  valid_612239 = validateParameter(valid_612239, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_612239 != nil:
    section.add "Action", valid_612239
  var valid_612240 = query.getOrDefault("Version")
  valid_612240 = validateParameter(valid_612240, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612240 != nil:
    section.add "Version", valid_612240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612241 = header.getOrDefault("X-Amz-Signature")
  valid_612241 = validateParameter(valid_612241, JString, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "X-Amz-Signature", valid_612241
  var valid_612242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "X-Amz-Content-Sha256", valid_612242
  var valid_612243 = header.getOrDefault("X-Amz-Date")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "X-Amz-Date", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-Credential")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Credential", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Security-Token")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Security-Token", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-Algorithm")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-Algorithm", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-SignedHeaders", valid_612247
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.1.key: JString
  ##   attributes.1.value: JString
  ##   attributes.2.key: JString
  ##   attributes.0.value: JString
  ##   attributes.0.key: JString
  ##   attributes.2.value: JString
  section = newJObject()
  var valid_612248 = formData.getOrDefault("attributes.1.key")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "attributes.1.key", valid_612248
  var valid_612249 = formData.getOrDefault("attributes.1.value")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "attributes.1.value", valid_612249
  var valid_612250 = formData.getOrDefault("attributes.2.key")
  valid_612250 = validateParameter(valid_612250, JString, required = false,
                                 default = nil)
  if valid_612250 != nil:
    section.add "attributes.2.key", valid_612250
  var valid_612251 = formData.getOrDefault("attributes.0.value")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "attributes.0.value", valid_612251
  var valid_612252 = formData.getOrDefault("attributes.0.key")
  valid_612252 = validateParameter(valid_612252, JString, required = false,
                                 default = nil)
  if valid_612252 != nil:
    section.add "attributes.0.key", valid_612252
  var valid_612253 = formData.getOrDefault("attributes.2.value")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "attributes.2.value", valid_612253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612254: Call_PostSetSMSAttributes_612236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_612254.validator(path, query, header, formData, body)
  let scheme = call_612254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612254.url(scheme.get, call_612254.host, call_612254.base,
                         call_612254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612254, url, valid)

proc call*(call_612255: Call_PostSetSMSAttributes_612236;
          attributes1Key: string = ""; attributes1Value: string = "";
          attributes2Key: string = ""; attributes0Value: string = "";
          Action: string = "SetSMSAttributes"; Version: string = "2010-03-31";
          attributes0Key: string = ""; attributes2Value: string = ""): Recallable =
  ## postSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes1Key: string
  ##   attributes1Value: string
  ##   attributes2Key: string
  ##   attributes0Value: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   attributes0Key: string
  ##   attributes2Value: string
  var query_612256 = newJObject()
  var formData_612257 = newJObject()
  add(formData_612257, "attributes.1.key", newJString(attributes1Key))
  add(formData_612257, "attributes.1.value", newJString(attributes1Value))
  add(formData_612257, "attributes.2.key", newJString(attributes2Key))
  add(formData_612257, "attributes.0.value", newJString(attributes0Value))
  add(query_612256, "Action", newJString(Action))
  add(query_612256, "Version", newJString(Version))
  add(formData_612257, "attributes.0.key", newJString(attributes0Key))
  add(formData_612257, "attributes.2.value", newJString(attributes2Value))
  result = call_612255.call(nil, query_612256, nil, formData_612257, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_612236(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_612237, base: "/",
    url: url_PostSetSMSAttributes_612238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_612215 = ref object of OpenApiRestCall_610658
proc url_GetSetSMSAttributes_612217(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSMSAttributes_612216(path: JsonNode; query: JsonNode;
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
  ##   attributes.0.key: JString
  ##   Action: JString (required)
  ##   attributes.1.key: JString
  ##   attributes.0.value: JString
  ##   Version: JString (required)
  ##   attributes.1.value: JString
  ##   attributes.2.value: JString
  section = newJObject()
  var valid_612218 = query.getOrDefault("attributes.2.key")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "attributes.2.key", valid_612218
  var valid_612219 = query.getOrDefault("attributes.0.key")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "attributes.0.key", valid_612219
  var valid_612220 = query.getOrDefault("Action")
  valid_612220 = validateParameter(valid_612220, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_612220 != nil:
    section.add "Action", valid_612220
  var valid_612221 = query.getOrDefault("attributes.1.key")
  valid_612221 = validateParameter(valid_612221, JString, required = false,
                                 default = nil)
  if valid_612221 != nil:
    section.add "attributes.1.key", valid_612221
  var valid_612222 = query.getOrDefault("attributes.0.value")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "attributes.0.value", valid_612222
  var valid_612223 = query.getOrDefault("Version")
  valid_612223 = validateParameter(valid_612223, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612223 != nil:
    section.add "Version", valid_612223
  var valid_612224 = query.getOrDefault("attributes.1.value")
  valid_612224 = validateParameter(valid_612224, JString, required = false,
                                 default = nil)
  if valid_612224 != nil:
    section.add "attributes.1.value", valid_612224
  var valid_612225 = query.getOrDefault("attributes.2.value")
  valid_612225 = validateParameter(valid_612225, JString, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "attributes.2.value", valid_612225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612226 = header.getOrDefault("X-Amz-Signature")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "X-Amz-Signature", valid_612226
  var valid_612227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-Content-Sha256", valid_612227
  var valid_612228 = header.getOrDefault("X-Amz-Date")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "X-Amz-Date", valid_612228
  var valid_612229 = header.getOrDefault("X-Amz-Credential")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Credential", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Security-Token")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Security-Token", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-Algorithm")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Algorithm", valid_612231
  var valid_612232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "X-Amz-SignedHeaders", valid_612232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612233: Call_GetSetSMSAttributes_612215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_612233.validator(path, query, header, formData, body)
  let scheme = call_612233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612233.url(scheme.get, call_612233.host, call_612233.base,
                         call_612233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612233, url, valid)

proc call*(call_612234: Call_GetSetSMSAttributes_612215;
          attributes2Key: string = ""; attributes0Key: string = "";
          Action: string = "SetSMSAttributes"; attributes1Key: string = "";
          attributes0Value: string = ""; Version: string = "2010-03-31";
          attributes1Value: string = ""; attributes2Value: string = ""): Recallable =
  ## getSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes2Key: string
  ##   attributes0Key: string
  ##   Action: string (required)
  ##   attributes1Key: string
  ##   attributes0Value: string
  ##   Version: string (required)
  ##   attributes1Value: string
  ##   attributes2Value: string
  var query_612235 = newJObject()
  add(query_612235, "attributes.2.key", newJString(attributes2Key))
  add(query_612235, "attributes.0.key", newJString(attributes0Key))
  add(query_612235, "Action", newJString(Action))
  add(query_612235, "attributes.1.key", newJString(attributes1Key))
  add(query_612235, "attributes.0.value", newJString(attributes0Value))
  add(query_612235, "Version", newJString(Version))
  add(query_612235, "attributes.1.value", newJString(attributes1Value))
  add(query_612235, "attributes.2.value", newJString(attributes2Value))
  result = call_612234.call(nil, query_612235, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_612215(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_612216, base: "/",
    url: url_GetSetSMSAttributes_612217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_612276 = ref object of OpenApiRestCall_610658
proc url_PostSetSubscriptionAttributes_612278(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSubscriptionAttributes_612277(path: JsonNode; query: JsonNode;
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
  var valid_612279 = query.getOrDefault("Action")
  valid_612279 = validateParameter(valid_612279, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_612279 != nil:
    section.add "Action", valid_612279
  var valid_612280 = query.getOrDefault("Version")
  valid_612280 = validateParameter(valid_612280, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612280 != nil:
    section.add "Version", valid_612280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612281 = header.getOrDefault("X-Amz-Signature")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "X-Amz-Signature", valid_612281
  var valid_612282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612282 = validateParameter(valid_612282, JString, required = false,
                                 default = nil)
  if valid_612282 != nil:
    section.add "X-Amz-Content-Sha256", valid_612282
  var valid_612283 = header.getOrDefault("X-Amz-Date")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "X-Amz-Date", valid_612283
  var valid_612284 = header.getOrDefault("X-Amz-Credential")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "X-Amz-Credential", valid_612284
  var valid_612285 = header.getOrDefault("X-Amz-Security-Token")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "X-Amz-Security-Token", valid_612285
  var valid_612286 = header.getOrDefault("X-Amz-Algorithm")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Algorithm", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-SignedHeaders", valid_612287
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_612288 = formData.getOrDefault("AttributeName")
  valid_612288 = validateParameter(valid_612288, JString, required = true,
                                 default = nil)
  if valid_612288 != nil:
    section.add "AttributeName", valid_612288
  var valid_612289 = formData.getOrDefault("SubscriptionArn")
  valid_612289 = validateParameter(valid_612289, JString, required = true,
                                 default = nil)
  if valid_612289 != nil:
    section.add "SubscriptionArn", valid_612289
  var valid_612290 = formData.getOrDefault("AttributeValue")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "AttributeValue", valid_612290
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612291: Call_PostSetSubscriptionAttributes_612276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_612291.validator(path, query, header, formData, body)
  let scheme = call_612291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612291.url(scheme.get, call_612291.host, call_612291.base,
                         call_612291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612291, url, valid)

proc call*(call_612292: Call_PostSetSubscriptionAttributes_612276;
          AttributeName: string; SubscriptionArn: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612293 = newJObject()
  var formData_612294 = newJObject()
  add(formData_612294, "AttributeName", newJString(AttributeName))
  add(formData_612294, "SubscriptionArn", newJString(SubscriptionArn))
  add(formData_612294, "AttributeValue", newJString(AttributeValue))
  add(query_612293, "Action", newJString(Action))
  add(query_612293, "Version", newJString(Version))
  result = call_612292.call(nil, query_612293, nil, formData_612294, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_612276(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_612277, base: "/",
    url: url_PostSetSubscriptionAttributes_612278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_612258 = ref object of OpenApiRestCall_610658
proc url_GetSetSubscriptionAttributes_612260(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSubscriptionAttributes_612259(path: JsonNode; query: JsonNode;
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
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   Action: JString (required)
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_612261 = query.getOrDefault("SubscriptionArn")
  valid_612261 = validateParameter(valid_612261, JString, required = true,
                                 default = nil)
  if valid_612261 != nil:
    section.add "SubscriptionArn", valid_612261
  var valid_612262 = query.getOrDefault("AttributeValue")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "AttributeValue", valid_612262
  var valid_612263 = query.getOrDefault("Action")
  valid_612263 = validateParameter(valid_612263, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_612263 != nil:
    section.add "Action", valid_612263
  var valid_612264 = query.getOrDefault("AttributeName")
  valid_612264 = validateParameter(valid_612264, JString, required = true,
                                 default = nil)
  if valid_612264 != nil:
    section.add "AttributeName", valid_612264
  var valid_612265 = query.getOrDefault("Version")
  valid_612265 = validateParameter(valid_612265, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612265 != nil:
    section.add "Version", valid_612265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612266 = header.getOrDefault("X-Amz-Signature")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-Signature", valid_612266
  var valid_612267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612267 = validateParameter(valid_612267, JString, required = false,
                                 default = nil)
  if valid_612267 != nil:
    section.add "X-Amz-Content-Sha256", valid_612267
  var valid_612268 = header.getOrDefault("X-Amz-Date")
  valid_612268 = validateParameter(valid_612268, JString, required = false,
                                 default = nil)
  if valid_612268 != nil:
    section.add "X-Amz-Date", valid_612268
  var valid_612269 = header.getOrDefault("X-Amz-Credential")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Credential", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-Security-Token")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-Security-Token", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-Algorithm")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Algorithm", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-SignedHeaders", valid_612272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612273: Call_GetSetSubscriptionAttributes_612258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_612273.validator(path, query, header, formData, body)
  let scheme = call_612273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612273.url(scheme.get, call_612273.host, call_612273.base,
                         call_612273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612273, url, valid)

proc call*(call_612274: Call_GetSetSubscriptionAttributes_612258;
          SubscriptionArn: string; AttributeName: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   Version: string (required)
  var query_612275 = newJObject()
  add(query_612275, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_612275, "AttributeValue", newJString(AttributeValue))
  add(query_612275, "Action", newJString(Action))
  add(query_612275, "AttributeName", newJString(AttributeName))
  add(query_612275, "Version", newJString(Version))
  result = call_612274.call(nil, query_612275, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_612258(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_612259, base: "/",
    url: url_GetSetSubscriptionAttributes_612260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_612313 = ref object of OpenApiRestCall_610658
proc url_PostSetTopicAttributes_612315(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetTopicAttributes_612314(path: JsonNode; query: JsonNode;
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
  var valid_612316 = query.getOrDefault("Action")
  valid_612316 = validateParameter(valid_612316, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_612316 != nil:
    section.add "Action", valid_612316
  var valid_612317 = query.getOrDefault("Version")
  valid_612317 = validateParameter(valid_612317, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612317 != nil:
    section.add "Version", valid_612317
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612318 = header.getOrDefault("X-Amz-Signature")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "X-Amz-Signature", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Content-Sha256", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-Date")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-Date", valid_612320
  var valid_612321 = header.getOrDefault("X-Amz-Credential")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-Credential", valid_612321
  var valid_612322 = header.getOrDefault("X-Amz-Security-Token")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "X-Amz-Security-Token", valid_612322
  var valid_612323 = header.getOrDefault("X-Amz-Algorithm")
  valid_612323 = validateParameter(valid_612323, JString, required = false,
                                 default = nil)
  if valid_612323 != nil:
    section.add "X-Amz-Algorithm", valid_612323
  var valid_612324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612324 = validateParameter(valid_612324, JString, required = false,
                                 default = nil)
  if valid_612324 != nil:
    section.add "X-Amz-SignedHeaders", valid_612324
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_612325 = formData.getOrDefault("AttributeName")
  valid_612325 = validateParameter(valid_612325, JString, required = true,
                                 default = nil)
  if valid_612325 != nil:
    section.add "AttributeName", valid_612325
  var valid_612326 = formData.getOrDefault("TopicArn")
  valid_612326 = validateParameter(valid_612326, JString, required = true,
                                 default = nil)
  if valid_612326 != nil:
    section.add "TopicArn", valid_612326
  var valid_612327 = formData.getOrDefault("AttributeValue")
  valid_612327 = validateParameter(valid_612327, JString, required = false,
                                 default = nil)
  if valid_612327 != nil:
    section.add "AttributeValue", valid_612327
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612328: Call_PostSetTopicAttributes_612313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_612328.validator(path, query, header, formData, body)
  let scheme = call_612328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612328.url(scheme.get, call_612328.host, call_612328.base,
                         call_612328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612328, url, valid)

proc call*(call_612329: Call_PostSetTopicAttributes_612313; AttributeName: string;
          TopicArn: string; AttributeValue: string = "";
          Action: string = "SetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612330 = newJObject()
  var formData_612331 = newJObject()
  add(formData_612331, "AttributeName", newJString(AttributeName))
  add(formData_612331, "TopicArn", newJString(TopicArn))
  add(formData_612331, "AttributeValue", newJString(AttributeValue))
  add(query_612330, "Action", newJString(Action))
  add(query_612330, "Version", newJString(Version))
  result = call_612329.call(nil, query_612330, nil, formData_612331, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_612313(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_612314, base: "/",
    url: url_PostSetTopicAttributes_612315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_612295 = ref object of OpenApiRestCall_610658
proc url_GetSetTopicAttributes_612297(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetTopicAttributes_612296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  ##   Action: JString (required)
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  section = newJObject()
  var valid_612298 = query.getOrDefault("AttributeValue")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "AttributeValue", valid_612298
  var valid_612299 = query.getOrDefault("Action")
  valid_612299 = validateParameter(valid_612299, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_612299 != nil:
    section.add "Action", valid_612299
  var valid_612300 = query.getOrDefault("AttributeName")
  valid_612300 = validateParameter(valid_612300, JString, required = true,
                                 default = nil)
  if valid_612300 != nil:
    section.add "AttributeName", valid_612300
  var valid_612301 = query.getOrDefault("Version")
  valid_612301 = validateParameter(valid_612301, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612301 != nil:
    section.add "Version", valid_612301
  var valid_612302 = query.getOrDefault("TopicArn")
  valid_612302 = validateParameter(valid_612302, JString, required = true,
                                 default = nil)
  if valid_612302 != nil:
    section.add "TopicArn", valid_612302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612303 = header.getOrDefault("X-Amz-Signature")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Signature", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-Content-Sha256", valid_612304
  var valid_612305 = header.getOrDefault("X-Amz-Date")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-Date", valid_612305
  var valid_612306 = header.getOrDefault("X-Amz-Credential")
  valid_612306 = validateParameter(valid_612306, JString, required = false,
                                 default = nil)
  if valid_612306 != nil:
    section.add "X-Amz-Credential", valid_612306
  var valid_612307 = header.getOrDefault("X-Amz-Security-Token")
  valid_612307 = validateParameter(valid_612307, JString, required = false,
                                 default = nil)
  if valid_612307 != nil:
    section.add "X-Amz-Security-Token", valid_612307
  var valid_612308 = header.getOrDefault("X-Amz-Algorithm")
  valid_612308 = validateParameter(valid_612308, JString, required = false,
                                 default = nil)
  if valid_612308 != nil:
    section.add "X-Amz-Algorithm", valid_612308
  var valid_612309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612309 = validateParameter(valid_612309, JString, required = false,
                                 default = nil)
  if valid_612309 != nil:
    section.add "X-Amz-SignedHeaders", valid_612309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612310: Call_GetSetTopicAttributes_612295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_612310.validator(path, query, header, formData, body)
  let scheme = call_612310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612310.url(scheme.get, call_612310.host, call_612310.base,
                         call_612310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612310, url, valid)

proc call*(call_612311: Call_GetSetTopicAttributes_612295; AttributeName: string;
          TopicArn: string; AttributeValue: string = "";
          Action: string = "SetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   Action: string (required)
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  var query_612312 = newJObject()
  add(query_612312, "AttributeValue", newJString(AttributeValue))
  add(query_612312, "Action", newJString(Action))
  add(query_612312, "AttributeName", newJString(AttributeName))
  add(query_612312, "Version", newJString(Version))
  add(query_612312, "TopicArn", newJString(TopicArn))
  result = call_612311.call(nil, query_612312, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_612295(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_612296, base: "/",
    url: url_GetSetTopicAttributes_612297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_612357 = ref object of OpenApiRestCall_610658
proc url_PostSubscribe_612359(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSubscribe_612358(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612360 = query.getOrDefault("Action")
  valid_612360 = validateParameter(valid_612360, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_612360 != nil:
    section.add "Action", valid_612360
  var valid_612361 = query.getOrDefault("Version")
  valid_612361 = validateParameter(valid_612361, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612361 != nil:
    section.add "Version", valid_612361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612362 = header.getOrDefault("X-Amz-Signature")
  valid_612362 = validateParameter(valid_612362, JString, required = false,
                                 default = nil)
  if valid_612362 != nil:
    section.add "X-Amz-Signature", valid_612362
  var valid_612363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612363 = validateParameter(valid_612363, JString, required = false,
                                 default = nil)
  if valid_612363 != nil:
    section.add "X-Amz-Content-Sha256", valid_612363
  var valid_612364 = header.getOrDefault("X-Amz-Date")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "X-Amz-Date", valid_612364
  var valid_612365 = header.getOrDefault("X-Amz-Credential")
  valid_612365 = validateParameter(valid_612365, JString, required = false,
                                 default = nil)
  if valid_612365 != nil:
    section.add "X-Amz-Credential", valid_612365
  var valid_612366 = header.getOrDefault("X-Amz-Security-Token")
  valid_612366 = validateParameter(valid_612366, JString, required = false,
                                 default = nil)
  if valid_612366 != nil:
    section.add "X-Amz-Security-Token", valid_612366
  var valid_612367 = header.getOrDefault("X-Amz-Algorithm")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-Algorithm", valid_612367
  var valid_612368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612368 = validateParameter(valid_612368, JString, required = false,
                                 default = nil)
  if valid_612368 != nil:
    section.add "X-Amz-SignedHeaders", valid_612368
  result.add "header", section
  ## parameters in `formData` object:
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_612369 = formData.getOrDefault("Endpoint")
  valid_612369 = validateParameter(valid_612369, JString, required = false,
                                 default = nil)
  if valid_612369 != nil:
    section.add "Endpoint", valid_612369
  var valid_612370 = formData.getOrDefault("Attributes.0.key")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "Attributes.0.key", valid_612370
  var valid_612371 = formData.getOrDefault("Attributes.2.value")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "Attributes.2.value", valid_612371
  var valid_612372 = formData.getOrDefault("Attributes.2.key")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "Attributes.2.key", valid_612372
  assert formData != nil,
        "formData argument is necessary due to required `Protocol` field"
  var valid_612373 = formData.getOrDefault("Protocol")
  valid_612373 = validateParameter(valid_612373, JString, required = true,
                                 default = nil)
  if valid_612373 != nil:
    section.add "Protocol", valid_612373
  var valid_612374 = formData.getOrDefault("Attributes.0.value")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "Attributes.0.value", valid_612374
  var valid_612375 = formData.getOrDefault("Attributes.1.key")
  valid_612375 = validateParameter(valid_612375, JString, required = false,
                                 default = nil)
  if valid_612375 != nil:
    section.add "Attributes.1.key", valid_612375
  var valid_612376 = formData.getOrDefault("TopicArn")
  valid_612376 = validateParameter(valid_612376, JString, required = true,
                                 default = nil)
  if valid_612376 != nil:
    section.add "TopicArn", valid_612376
  var valid_612377 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_612377 = validateParameter(valid_612377, JBool, required = false, default = nil)
  if valid_612377 != nil:
    section.add "ReturnSubscriptionArn", valid_612377
  var valid_612378 = formData.getOrDefault("Attributes.1.value")
  valid_612378 = validateParameter(valid_612378, JString, required = false,
                                 default = nil)
  if valid_612378 != nil:
    section.add "Attributes.1.value", valid_612378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612379: Call_PostSubscribe_612357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_612379.validator(path, query, header, formData, body)
  let scheme = call_612379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612379.url(scheme.get, call_612379.host, call_612379.base,
                         call_612379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612379, url, valid)

proc call*(call_612380: Call_PostSubscribe_612357; Protocol: string;
          TopicArn: string; Endpoint: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          ReturnSubscriptionArn: bool = false; Action: string = "Subscribe";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_612381 = newJObject()
  var formData_612382 = newJObject()
  add(formData_612382, "Endpoint", newJString(Endpoint))
  add(formData_612382, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_612382, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_612382, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_612382, "Protocol", newJString(Protocol))
  add(formData_612382, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_612382, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_612382, "TopicArn", newJString(TopicArn))
  add(formData_612382, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_612381, "Action", newJString(Action))
  add(query_612381, "Version", newJString(Version))
  add(formData_612382, "Attributes.1.value", newJString(Attributes1Value))
  result = call_612380.call(nil, query_612381, nil, formData_612382, nil)

var postSubscribe* = Call_PostSubscribe_612357(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_612358,
    base: "/", url: url_PostSubscribe_612359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_612332 = ref object of OpenApiRestCall_610658
proc url_GetSubscribe_612334(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSubscribe_612333(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Action: JString (required)
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  section = newJObject()
  var valid_612335 = query.getOrDefault("Attributes.1.key")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "Attributes.1.key", valid_612335
  var valid_612336 = query.getOrDefault("Attributes.0.value")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "Attributes.0.value", valid_612336
  var valid_612337 = query.getOrDefault("Endpoint")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "Endpoint", valid_612337
  var valid_612338 = query.getOrDefault("Attributes.0.key")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "Attributes.0.key", valid_612338
  var valid_612339 = query.getOrDefault("Attributes.2.value")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "Attributes.2.value", valid_612339
  var valid_612340 = query.getOrDefault("Attributes.1.value")
  valid_612340 = validateParameter(valid_612340, JString, required = false,
                                 default = nil)
  if valid_612340 != nil:
    section.add "Attributes.1.value", valid_612340
  var valid_612341 = query.getOrDefault("Action")
  valid_612341 = validateParameter(valid_612341, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_612341 != nil:
    section.add "Action", valid_612341
  var valid_612342 = query.getOrDefault("Protocol")
  valid_612342 = validateParameter(valid_612342, JString, required = true,
                                 default = nil)
  if valid_612342 != nil:
    section.add "Protocol", valid_612342
  var valid_612343 = query.getOrDefault("ReturnSubscriptionArn")
  valid_612343 = validateParameter(valid_612343, JBool, required = false, default = nil)
  if valid_612343 != nil:
    section.add "ReturnSubscriptionArn", valid_612343
  var valid_612344 = query.getOrDefault("Version")
  valid_612344 = validateParameter(valid_612344, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612344 != nil:
    section.add "Version", valid_612344
  var valid_612345 = query.getOrDefault("Attributes.2.key")
  valid_612345 = validateParameter(valid_612345, JString, required = false,
                                 default = nil)
  if valid_612345 != nil:
    section.add "Attributes.2.key", valid_612345
  var valid_612346 = query.getOrDefault("TopicArn")
  valid_612346 = validateParameter(valid_612346, JString, required = true,
                                 default = nil)
  if valid_612346 != nil:
    section.add "TopicArn", valid_612346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612347 = header.getOrDefault("X-Amz-Signature")
  valid_612347 = validateParameter(valid_612347, JString, required = false,
                                 default = nil)
  if valid_612347 != nil:
    section.add "X-Amz-Signature", valid_612347
  var valid_612348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612348 = validateParameter(valid_612348, JString, required = false,
                                 default = nil)
  if valid_612348 != nil:
    section.add "X-Amz-Content-Sha256", valid_612348
  var valid_612349 = header.getOrDefault("X-Amz-Date")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Date", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-Credential")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-Credential", valid_612350
  var valid_612351 = header.getOrDefault("X-Amz-Security-Token")
  valid_612351 = validateParameter(valid_612351, JString, required = false,
                                 default = nil)
  if valid_612351 != nil:
    section.add "X-Amz-Security-Token", valid_612351
  var valid_612352 = header.getOrDefault("X-Amz-Algorithm")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-Algorithm", valid_612352
  var valid_612353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "X-Amz-SignedHeaders", valid_612353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612354: Call_GetSubscribe_612332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_612354.validator(path, query, header, formData, body)
  let scheme = call_612354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612354.url(scheme.get, call_612354.host, call_612354.base,
                         call_612354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612354, url, valid)

proc call*(call_612355: Call_GetSubscribe_612332; Protocol: string; TopicArn: string;
          Attributes1Key: string = ""; Attributes0Value: string = "";
          Endpoint: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes1Value: string = "";
          Action: string = "Subscribe"; ReturnSubscriptionArn: bool = false;
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Action: string (required)
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Version: string (required)
  ##   Attributes2Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  var query_612356 = newJObject()
  add(query_612356, "Attributes.1.key", newJString(Attributes1Key))
  add(query_612356, "Attributes.0.value", newJString(Attributes0Value))
  add(query_612356, "Endpoint", newJString(Endpoint))
  add(query_612356, "Attributes.0.key", newJString(Attributes0Key))
  add(query_612356, "Attributes.2.value", newJString(Attributes2Value))
  add(query_612356, "Attributes.1.value", newJString(Attributes1Value))
  add(query_612356, "Action", newJString(Action))
  add(query_612356, "Protocol", newJString(Protocol))
  add(query_612356, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_612356, "Version", newJString(Version))
  add(query_612356, "Attributes.2.key", newJString(Attributes2Key))
  add(query_612356, "TopicArn", newJString(TopicArn))
  result = call_612355.call(nil, query_612356, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_612332(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_612333, base: "/",
    url: url_GetSubscribe_612334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_612400 = ref object of OpenApiRestCall_610658
proc url_PostTagResource_612402(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostTagResource_612401(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612403 = query.getOrDefault("Action")
  valid_612403 = validateParameter(valid_612403, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_612403 != nil:
    section.add "Action", valid_612403
  var valid_612404 = query.getOrDefault("Version")
  valid_612404 = validateParameter(valid_612404, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612404 != nil:
    section.add "Version", valid_612404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612405 = header.getOrDefault("X-Amz-Signature")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Signature", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Content-Sha256", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Date")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Date", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-Credential")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-Credential", valid_612408
  var valid_612409 = header.getOrDefault("X-Amz-Security-Token")
  valid_612409 = validateParameter(valid_612409, JString, required = false,
                                 default = nil)
  if valid_612409 != nil:
    section.add "X-Amz-Security-Token", valid_612409
  var valid_612410 = header.getOrDefault("X-Amz-Algorithm")
  valid_612410 = validateParameter(valid_612410, JString, required = false,
                                 default = nil)
  if valid_612410 != nil:
    section.add "X-Amz-Algorithm", valid_612410
  var valid_612411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612411 = validateParameter(valid_612411, JString, required = false,
                                 default = nil)
  if valid_612411 != nil:
    section.add "X-Amz-SignedHeaders", valid_612411
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_612412 = formData.getOrDefault("ResourceArn")
  valid_612412 = validateParameter(valid_612412, JString, required = true,
                                 default = nil)
  if valid_612412 != nil:
    section.add "ResourceArn", valid_612412
  var valid_612413 = formData.getOrDefault("Tags")
  valid_612413 = validateParameter(valid_612413, JArray, required = true, default = nil)
  if valid_612413 != nil:
    section.add "Tags", valid_612413
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612414: Call_PostTagResource_612400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_612414.validator(path, query, header, formData, body)
  let scheme = call_612414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612414.url(scheme.get, call_612414.host, call_612414.base,
                         call_612414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612414, url, valid)

proc call*(call_612415: Call_PostTagResource_612400; ResourceArn: string;
          Tags: JsonNode; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Version: string (required)
  var query_612416 = newJObject()
  var formData_612417 = newJObject()
  add(formData_612417, "ResourceArn", newJString(ResourceArn))
  add(query_612416, "Action", newJString(Action))
  if Tags != nil:
    formData_612417.add "Tags", Tags
  add(query_612416, "Version", newJString(Version))
  result = call_612415.call(nil, query_612416, nil, formData_612417, nil)

var postTagResource* = Call_PostTagResource_612400(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_612401,
    base: "/", url: url_PostTagResource_612402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_612383 = ref object of OpenApiRestCall_610658
proc url_GetTagResource_612385(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTagResource_612384(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_612386 = query.getOrDefault("Tags")
  valid_612386 = validateParameter(valid_612386, JArray, required = true, default = nil)
  if valid_612386 != nil:
    section.add "Tags", valid_612386
  var valid_612387 = query.getOrDefault("ResourceArn")
  valid_612387 = validateParameter(valid_612387, JString, required = true,
                                 default = nil)
  if valid_612387 != nil:
    section.add "ResourceArn", valid_612387
  var valid_612388 = query.getOrDefault("Action")
  valid_612388 = validateParameter(valid_612388, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_612388 != nil:
    section.add "Action", valid_612388
  var valid_612389 = query.getOrDefault("Version")
  valid_612389 = validateParameter(valid_612389, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612389 != nil:
    section.add "Version", valid_612389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612390 = header.getOrDefault("X-Amz-Signature")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-Signature", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-Content-Sha256", valid_612391
  var valid_612392 = header.getOrDefault("X-Amz-Date")
  valid_612392 = validateParameter(valid_612392, JString, required = false,
                                 default = nil)
  if valid_612392 != nil:
    section.add "X-Amz-Date", valid_612392
  var valid_612393 = header.getOrDefault("X-Amz-Credential")
  valid_612393 = validateParameter(valid_612393, JString, required = false,
                                 default = nil)
  if valid_612393 != nil:
    section.add "X-Amz-Credential", valid_612393
  var valid_612394 = header.getOrDefault("X-Amz-Security-Token")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "X-Amz-Security-Token", valid_612394
  var valid_612395 = header.getOrDefault("X-Amz-Algorithm")
  valid_612395 = validateParameter(valid_612395, JString, required = false,
                                 default = nil)
  if valid_612395 != nil:
    section.add "X-Amz-Algorithm", valid_612395
  var valid_612396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612396 = validateParameter(valid_612396, JString, required = false,
                                 default = nil)
  if valid_612396 != nil:
    section.add "X-Amz-SignedHeaders", valid_612396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612397: Call_GetTagResource_612383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_612397.validator(path, query, header, formData, body)
  let scheme = call_612397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612397.url(scheme.get, call_612397.host, call_612397.base,
                         call_612397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612397, url, valid)

proc call*(call_612398: Call_GetTagResource_612383; Tags: JsonNode;
          ResourceArn: string; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612399 = newJObject()
  if Tags != nil:
    query_612399.add "Tags", Tags
  add(query_612399, "ResourceArn", newJString(ResourceArn))
  add(query_612399, "Action", newJString(Action))
  add(query_612399, "Version", newJString(Version))
  result = call_612398.call(nil, query_612399, nil, nil, nil)

var getTagResource* = Call_GetTagResource_612383(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_612384,
    base: "/", url: url_GetTagResource_612385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_612434 = ref object of OpenApiRestCall_610658
proc url_PostUnsubscribe_612436(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUnsubscribe_612435(path: JsonNode; query: JsonNode;
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
  var valid_612437 = query.getOrDefault("Action")
  valid_612437 = validateParameter(valid_612437, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_612437 != nil:
    section.add "Action", valid_612437
  var valid_612438 = query.getOrDefault("Version")
  valid_612438 = validateParameter(valid_612438, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612438 != nil:
    section.add "Version", valid_612438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612439 = header.getOrDefault("X-Amz-Signature")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-Signature", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Content-Sha256", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-Date")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-Date", valid_612441
  var valid_612442 = header.getOrDefault("X-Amz-Credential")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "X-Amz-Credential", valid_612442
  var valid_612443 = header.getOrDefault("X-Amz-Security-Token")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "X-Amz-Security-Token", valid_612443
  var valid_612444 = header.getOrDefault("X-Amz-Algorithm")
  valid_612444 = validateParameter(valid_612444, JString, required = false,
                                 default = nil)
  if valid_612444 != nil:
    section.add "X-Amz-Algorithm", valid_612444
  var valid_612445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612445 = validateParameter(valid_612445, JString, required = false,
                                 default = nil)
  if valid_612445 != nil:
    section.add "X-Amz-SignedHeaders", valid_612445
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_612446 = formData.getOrDefault("SubscriptionArn")
  valid_612446 = validateParameter(valid_612446, JString, required = true,
                                 default = nil)
  if valid_612446 != nil:
    section.add "SubscriptionArn", valid_612446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612447: Call_PostUnsubscribe_612434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_612447.validator(path, query, header, formData, body)
  let scheme = call_612447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612447.url(scheme.get, call_612447.host, call_612447.base,
                         call_612447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612447, url, valid)

proc call*(call_612448: Call_PostUnsubscribe_612434; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612449 = newJObject()
  var formData_612450 = newJObject()
  add(formData_612450, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_612449, "Action", newJString(Action))
  add(query_612449, "Version", newJString(Version))
  result = call_612448.call(nil, query_612449, nil, formData_612450, nil)

var postUnsubscribe* = Call_PostUnsubscribe_612434(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_612435,
    base: "/", url: url_PostUnsubscribe_612436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_612418 = ref object of OpenApiRestCall_610658
proc url_GetUnsubscribe_612420(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUnsubscribe_612419(path: JsonNode; query: JsonNode;
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
  var valid_612421 = query.getOrDefault("SubscriptionArn")
  valid_612421 = validateParameter(valid_612421, JString, required = true,
                                 default = nil)
  if valid_612421 != nil:
    section.add "SubscriptionArn", valid_612421
  var valid_612422 = query.getOrDefault("Action")
  valid_612422 = validateParameter(valid_612422, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_612422 != nil:
    section.add "Action", valid_612422
  var valid_612423 = query.getOrDefault("Version")
  valid_612423 = validateParameter(valid_612423, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612423 != nil:
    section.add "Version", valid_612423
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612424 = header.getOrDefault("X-Amz-Signature")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-Signature", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Content-Sha256", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-Date")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-Date", valid_612426
  var valid_612427 = header.getOrDefault("X-Amz-Credential")
  valid_612427 = validateParameter(valid_612427, JString, required = false,
                                 default = nil)
  if valid_612427 != nil:
    section.add "X-Amz-Credential", valid_612427
  var valid_612428 = header.getOrDefault("X-Amz-Security-Token")
  valid_612428 = validateParameter(valid_612428, JString, required = false,
                                 default = nil)
  if valid_612428 != nil:
    section.add "X-Amz-Security-Token", valid_612428
  var valid_612429 = header.getOrDefault("X-Amz-Algorithm")
  valid_612429 = validateParameter(valid_612429, JString, required = false,
                                 default = nil)
  if valid_612429 != nil:
    section.add "X-Amz-Algorithm", valid_612429
  var valid_612430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612430 = validateParameter(valid_612430, JString, required = false,
                                 default = nil)
  if valid_612430 != nil:
    section.add "X-Amz-SignedHeaders", valid_612430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612431: Call_GetUnsubscribe_612418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_612431.validator(path, query, header, formData, body)
  let scheme = call_612431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612431.url(scheme.get, call_612431.host, call_612431.base,
                         call_612431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612431, url, valid)

proc call*(call_612432: Call_GetUnsubscribe_612418; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612433 = newJObject()
  add(query_612433, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_612433, "Action", newJString(Action))
  add(query_612433, "Version", newJString(Version))
  result = call_612432.call(nil, query_612433, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_612418(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_612419,
    base: "/", url: url_GetUnsubscribe_612420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_612468 = ref object of OpenApiRestCall_610658
proc url_PostUntagResource_612470(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUntagResource_612469(path: JsonNode; query: JsonNode;
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
  var valid_612471 = query.getOrDefault("Action")
  valid_612471 = validateParameter(valid_612471, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_612471 != nil:
    section.add "Action", valid_612471
  var valid_612472 = query.getOrDefault("Version")
  valid_612472 = validateParameter(valid_612472, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612472 != nil:
    section.add "Version", valid_612472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612473 = header.getOrDefault("X-Amz-Signature")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Signature", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Content-Sha256", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-Date")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-Date", valid_612475
  var valid_612476 = header.getOrDefault("X-Amz-Credential")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "X-Amz-Credential", valid_612476
  var valid_612477 = header.getOrDefault("X-Amz-Security-Token")
  valid_612477 = validateParameter(valid_612477, JString, required = false,
                                 default = nil)
  if valid_612477 != nil:
    section.add "X-Amz-Security-Token", valid_612477
  var valid_612478 = header.getOrDefault("X-Amz-Algorithm")
  valid_612478 = validateParameter(valid_612478, JString, required = false,
                                 default = nil)
  if valid_612478 != nil:
    section.add "X-Amz-Algorithm", valid_612478
  var valid_612479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612479 = validateParameter(valid_612479, JString, required = false,
                                 default = nil)
  if valid_612479 != nil:
    section.add "X-Amz-SignedHeaders", valid_612479
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_612480 = formData.getOrDefault("TagKeys")
  valid_612480 = validateParameter(valid_612480, JArray, required = true, default = nil)
  if valid_612480 != nil:
    section.add "TagKeys", valid_612480
  var valid_612481 = formData.getOrDefault("ResourceArn")
  valid_612481 = validateParameter(valid_612481, JString, required = true,
                                 default = nil)
  if valid_612481 != nil:
    section.add "ResourceArn", valid_612481
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612482: Call_PostUntagResource_612468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_612482.validator(path, query, header, formData, body)
  let scheme = call_612482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612482.url(scheme.get, call_612482.host, call_612482.base,
                         call_612482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612482, url, valid)

proc call*(call_612483: Call_PostUntagResource_612468; TagKeys: JsonNode;
          ResourceArn: string; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612484 = newJObject()
  var formData_612485 = newJObject()
  if TagKeys != nil:
    formData_612485.add "TagKeys", TagKeys
  add(formData_612485, "ResourceArn", newJString(ResourceArn))
  add(query_612484, "Action", newJString(Action))
  add(query_612484, "Version", newJString(Version))
  result = call_612483.call(nil, query_612484, nil, formData_612485, nil)

var postUntagResource* = Call_PostUntagResource_612468(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_612469,
    base: "/", url: url_PostUntagResource_612470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_612451 = ref object of OpenApiRestCall_610658
proc url_GetUntagResource_612453(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUntagResource_612452(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TagKeys` field"
  var valid_612454 = query.getOrDefault("TagKeys")
  valid_612454 = validateParameter(valid_612454, JArray, required = true, default = nil)
  if valid_612454 != nil:
    section.add "TagKeys", valid_612454
  var valid_612455 = query.getOrDefault("ResourceArn")
  valid_612455 = validateParameter(valid_612455, JString, required = true,
                                 default = nil)
  if valid_612455 != nil:
    section.add "ResourceArn", valid_612455
  var valid_612456 = query.getOrDefault("Action")
  valid_612456 = validateParameter(valid_612456, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_612456 != nil:
    section.add "Action", valid_612456
  var valid_612457 = query.getOrDefault("Version")
  valid_612457 = validateParameter(valid_612457, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_612457 != nil:
    section.add "Version", valid_612457
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612458 = header.getOrDefault("X-Amz-Signature")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-Signature", valid_612458
  var valid_612459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612459 = validateParameter(valid_612459, JString, required = false,
                                 default = nil)
  if valid_612459 != nil:
    section.add "X-Amz-Content-Sha256", valid_612459
  var valid_612460 = header.getOrDefault("X-Amz-Date")
  valid_612460 = validateParameter(valid_612460, JString, required = false,
                                 default = nil)
  if valid_612460 != nil:
    section.add "X-Amz-Date", valid_612460
  var valid_612461 = header.getOrDefault("X-Amz-Credential")
  valid_612461 = validateParameter(valid_612461, JString, required = false,
                                 default = nil)
  if valid_612461 != nil:
    section.add "X-Amz-Credential", valid_612461
  var valid_612462 = header.getOrDefault("X-Amz-Security-Token")
  valid_612462 = validateParameter(valid_612462, JString, required = false,
                                 default = nil)
  if valid_612462 != nil:
    section.add "X-Amz-Security-Token", valid_612462
  var valid_612463 = header.getOrDefault("X-Amz-Algorithm")
  valid_612463 = validateParameter(valid_612463, JString, required = false,
                                 default = nil)
  if valid_612463 != nil:
    section.add "X-Amz-Algorithm", valid_612463
  var valid_612464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612464 = validateParameter(valid_612464, JString, required = false,
                                 default = nil)
  if valid_612464 != nil:
    section.add "X-Amz-SignedHeaders", valid_612464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612465: Call_GetUntagResource_612451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_612465.validator(path, query, header, formData, body)
  let scheme = call_612465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612465.url(scheme.get, call_612465.host, call_612465.base,
                         call_612465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612465, url, valid)

proc call*(call_612466: Call_GetUntagResource_612451; TagKeys: JsonNode;
          ResourceArn: string; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612467 = newJObject()
  if TagKeys != nil:
    query_612467.add "TagKeys", TagKeys
  add(query_612467, "ResourceArn", newJString(ResourceArn))
  add(query_612467, "Action", newJString(Action))
  add(query_612467, "Version", newJString(Version))
  result = call_612466.call(nil, query_612467, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_612451(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_612452,
    base: "/", url: url_GetUntagResource_612453,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers.del "Host"
  recall.url = $url

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
