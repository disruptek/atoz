
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_594048 = ref object of OpenApiRestCall_593437
proc url_PostAddPermission_594050(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddPermission_594049(path: JsonNode; query: JsonNode;
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
  var valid_594051 = query.getOrDefault("Action")
  valid_594051 = validateParameter(valid_594051, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_594051 != nil:
    section.add "Action", valid_594051
  var valid_594052 = query.getOrDefault("Version")
  valid_594052 = validateParameter(valid_594052, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594052 != nil:
    section.add "Version", valid_594052
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
  var valid_594053 = header.getOrDefault("X-Amz-Date")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Date", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Security-Token")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Security-Token", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Content-Sha256", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Algorithm")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Algorithm", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Signature")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Signature", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-SignedHeaders", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Credential")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Credential", valid_594059
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
  var valid_594060 = formData.getOrDefault("TopicArn")
  valid_594060 = validateParameter(valid_594060, JString, required = true,
                                 default = nil)
  if valid_594060 != nil:
    section.add "TopicArn", valid_594060
  var valid_594061 = formData.getOrDefault("AWSAccountId")
  valid_594061 = validateParameter(valid_594061, JArray, required = true, default = nil)
  if valid_594061 != nil:
    section.add "AWSAccountId", valid_594061
  var valid_594062 = formData.getOrDefault("Label")
  valid_594062 = validateParameter(valid_594062, JString, required = true,
                                 default = nil)
  if valid_594062 != nil:
    section.add "Label", valid_594062
  var valid_594063 = formData.getOrDefault("ActionName")
  valid_594063 = validateParameter(valid_594063, JArray, required = true, default = nil)
  if valid_594063 != nil:
    section.add "ActionName", valid_594063
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594064: Call_PostAddPermission_594048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_594064.validator(path, query, header, formData, body)
  let scheme = call_594064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594064.url(scheme.get, call_594064.host, call_594064.base,
                         call_594064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594064, url, valid)

proc call*(call_594065: Call_PostAddPermission_594048; TopicArn: string;
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
  var query_594066 = newJObject()
  var formData_594067 = newJObject()
  add(formData_594067, "TopicArn", newJString(TopicArn))
  if AWSAccountId != nil:
    formData_594067.add "AWSAccountId", AWSAccountId
  add(formData_594067, "Label", newJString(Label))
  add(query_594066, "Action", newJString(Action))
  if ActionName != nil:
    formData_594067.add "ActionName", ActionName
  add(query_594066, "Version", newJString(Version))
  result = call_594065.call(nil, query_594066, nil, formData_594067, nil)

var postAddPermission* = Call_PostAddPermission_594048(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_594049,
    base: "/", url: url_PostAddPermission_594050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_593774 = ref object of OpenApiRestCall_593437
proc url_GetAddPermission_593776(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddPermission_593775(path: JsonNode; query: JsonNode;
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
  var valid_593888 = query.getOrDefault("ActionName")
  valid_593888 = validateParameter(valid_593888, JArray, required = true, default = nil)
  if valid_593888 != nil:
    section.add "ActionName", valid_593888
  var valid_593902 = query.getOrDefault("Action")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_593902 != nil:
    section.add "Action", valid_593902
  var valid_593903 = query.getOrDefault("TopicArn")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = nil)
  if valid_593903 != nil:
    section.add "TopicArn", valid_593903
  var valid_593904 = query.getOrDefault("Version")
  valid_593904 = validateParameter(valid_593904, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593904 != nil:
    section.add "Version", valid_593904
  var valid_593905 = query.getOrDefault("Label")
  valid_593905 = validateParameter(valid_593905, JString, required = true,
                                 default = nil)
  if valid_593905 != nil:
    section.add "Label", valid_593905
  var valid_593906 = query.getOrDefault("AWSAccountId")
  valid_593906 = validateParameter(valid_593906, JArray, required = true, default = nil)
  if valid_593906 != nil:
    section.add "AWSAccountId", valid_593906
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
  var valid_593907 = header.getOrDefault("X-Amz-Date")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Date", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Security-Token")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Security-Token", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Content-Sha256", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Algorithm")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Algorithm", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-Signature")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-Signature", valid_593911
  var valid_593912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593912 = validateParameter(valid_593912, JString, required = false,
                                 default = nil)
  if valid_593912 != nil:
    section.add "X-Amz-SignedHeaders", valid_593912
  var valid_593913 = header.getOrDefault("X-Amz-Credential")
  valid_593913 = validateParameter(valid_593913, JString, required = false,
                                 default = nil)
  if valid_593913 != nil:
    section.add "X-Amz-Credential", valid_593913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593936: Call_GetAddPermission_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_593936.validator(path, query, header, formData, body)
  let scheme = call_593936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593936.url(scheme.get, call_593936.host, call_593936.base,
                         call_593936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593936, url, valid)

proc call*(call_594007: Call_GetAddPermission_593774; ActionName: JsonNode;
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
  var query_594008 = newJObject()
  if ActionName != nil:
    query_594008.add "ActionName", ActionName
  add(query_594008, "Action", newJString(Action))
  add(query_594008, "TopicArn", newJString(TopicArn))
  add(query_594008, "Version", newJString(Version))
  add(query_594008, "Label", newJString(Label))
  if AWSAccountId != nil:
    query_594008.add "AWSAccountId", AWSAccountId
  result = call_594007.call(nil, query_594008, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_593774(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_593775,
    base: "/", url: url_GetAddPermission_593776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_594084 = ref object of OpenApiRestCall_593437
proc url_PostCheckIfPhoneNumberIsOptedOut_594086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCheckIfPhoneNumberIsOptedOut_594085(path: JsonNode;
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
  var valid_594087 = query.getOrDefault("Action")
  valid_594087 = validateParameter(valid_594087, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_594087 != nil:
    section.add "Action", valid_594087
  var valid_594088 = query.getOrDefault("Version")
  valid_594088 = validateParameter(valid_594088, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594088 != nil:
    section.add "Version", valid_594088
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
  var valid_594089 = header.getOrDefault("X-Amz-Date")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Date", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Security-Token")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Security-Token", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Content-Sha256", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Algorithm")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Algorithm", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Signature")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Signature", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-SignedHeaders", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Credential")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Credential", valid_594095
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_594096 = formData.getOrDefault("phoneNumber")
  valid_594096 = validateParameter(valid_594096, JString, required = true,
                                 default = nil)
  if valid_594096 != nil:
    section.add "phoneNumber", valid_594096
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594097: Call_PostCheckIfPhoneNumberIsOptedOut_594084;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_594097.validator(path, query, header, formData, body)
  let scheme = call_594097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594097.url(scheme.get, call_594097.host, call_594097.base,
                         call_594097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594097, url, valid)

proc call*(call_594098: Call_PostCheckIfPhoneNumberIsOptedOut_594084;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Version: string (required)
  var query_594099 = newJObject()
  var formData_594100 = newJObject()
  add(query_594099, "Action", newJString(Action))
  add(formData_594100, "phoneNumber", newJString(phoneNumber))
  add(query_594099, "Version", newJString(Version))
  result = call_594098.call(nil, query_594099, nil, formData_594100, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_594084(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_594085, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_594086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_594068 = ref object of OpenApiRestCall_593437
proc url_GetCheckIfPhoneNumberIsOptedOut_594070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCheckIfPhoneNumberIsOptedOut_594069(path: JsonNode;
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
  var valid_594071 = query.getOrDefault("phoneNumber")
  valid_594071 = validateParameter(valid_594071, JString, required = true,
                                 default = nil)
  if valid_594071 != nil:
    section.add "phoneNumber", valid_594071
  var valid_594072 = query.getOrDefault("Action")
  valid_594072 = validateParameter(valid_594072, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_594072 != nil:
    section.add "Action", valid_594072
  var valid_594073 = query.getOrDefault("Version")
  valid_594073 = validateParameter(valid_594073, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594073 != nil:
    section.add "Version", valid_594073
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
  var valid_594074 = header.getOrDefault("X-Amz-Date")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Date", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Security-Token")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Security-Token", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Content-Sha256", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Algorithm")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Algorithm", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Signature")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Signature", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-SignedHeaders", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Credential")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Credential", valid_594080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594081: Call_GetCheckIfPhoneNumberIsOptedOut_594068;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_594081.validator(path, query, header, formData, body)
  let scheme = call_594081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594081.url(scheme.get, call_594081.host, call_594081.base,
                         call_594081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594081, url, valid)

proc call*(call_594082: Call_GetCheckIfPhoneNumberIsOptedOut_594068;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594083 = newJObject()
  add(query_594083, "phoneNumber", newJString(phoneNumber))
  add(query_594083, "Action", newJString(Action))
  add(query_594083, "Version", newJString(Version))
  result = call_594082.call(nil, query_594083, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_594068(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_594069, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_594070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_594119 = ref object of OpenApiRestCall_593437
proc url_PostConfirmSubscription_594121(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostConfirmSubscription_594120(path: JsonNode; query: JsonNode;
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
  var valid_594122 = query.getOrDefault("Action")
  valid_594122 = validateParameter(valid_594122, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_594122 != nil:
    section.add "Action", valid_594122
  var valid_594123 = query.getOrDefault("Version")
  valid_594123 = validateParameter(valid_594123, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594123 != nil:
    section.add "Version", valid_594123
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
  var valid_594124 = header.getOrDefault("X-Amz-Date")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Date", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Security-Token")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Security-Token", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Content-Sha256", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Algorithm")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Algorithm", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Signature")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Signature", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-SignedHeaders", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Credential")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Credential", valid_594130
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
  var valid_594131 = formData.getOrDefault("TopicArn")
  valid_594131 = validateParameter(valid_594131, JString, required = true,
                                 default = nil)
  if valid_594131 != nil:
    section.add "TopicArn", valid_594131
  var valid_594132 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_594132
  var valid_594133 = formData.getOrDefault("Token")
  valid_594133 = validateParameter(valid_594133, JString, required = true,
                                 default = nil)
  if valid_594133 != nil:
    section.add "Token", valid_594133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594134: Call_PostConfirmSubscription_594119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_594134.validator(path, query, header, formData, body)
  let scheme = call_594134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594134.url(scheme.get, call_594134.host, call_594134.base,
                         call_594134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594134, url, valid)

proc call*(call_594135: Call_PostConfirmSubscription_594119; TopicArn: string;
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
  var query_594136 = newJObject()
  var formData_594137 = newJObject()
  add(formData_594137, "TopicArn", newJString(TopicArn))
  add(formData_594137, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_594136, "Action", newJString(Action))
  add(query_594136, "Version", newJString(Version))
  add(formData_594137, "Token", newJString(Token))
  result = call_594135.call(nil, query_594136, nil, formData_594137, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_594119(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_594120, base: "/",
    url: url_PostConfirmSubscription_594121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_594101 = ref object of OpenApiRestCall_593437
proc url_GetConfirmSubscription_594103(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConfirmSubscription_594102(path: JsonNode; query: JsonNode;
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
  var valid_594104 = query.getOrDefault("Token")
  valid_594104 = validateParameter(valid_594104, JString, required = true,
                                 default = nil)
  if valid_594104 != nil:
    section.add "Token", valid_594104
  var valid_594105 = query.getOrDefault("Action")
  valid_594105 = validateParameter(valid_594105, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_594105 != nil:
    section.add "Action", valid_594105
  var valid_594106 = query.getOrDefault("TopicArn")
  valid_594106 = validateParameter(valid_594106, JString, required = true,
                                 default = nil)
  if valid_594106 != nil:
    section.add "TopicArn", valid_594106
  var valid_594107 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_594107
  var valid_594108 = query.getOrDefault("Version")
  valid_594108 = validateParameter(valid_594108, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594108 != nil:
    section.add "Version", valid_594108
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
  var valid_594109 = header.getOrDefault("X-Amz-Date")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Date", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Security-Token")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Security-Token", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Content-Sha256", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Algorithm")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Algorithm", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Signature")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Signature", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-SignedHeaders", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594116: Call_GetConfirmSubscription_594101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_594116.validator(path, query, header, formData, body)
  let scheme = call_594116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594116.url(scheme.get, call_594116.host, call_594116.base,
                         call_594116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594116, url, valid)

proc call*(call_594117: Call_GetConfirmSubscription_594101; Token: string;
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
  var query_594118 = newJObject()
  add(query_594118, "Token", newJString(Token))
  add(query_594118, "Action", newJString(Action))
  add(query_594118, "TopicArn", newJString(TopicArn))
  add(query_594118, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_594118, "Version", newJString(Version))
  result = call_594117.call(nil, query_594118, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_594101(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_594102, base: "/",
    url: url_GetConfirmSubscription_594103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_594161 = ref object of OpenApiRestCall_593437
proc url_PostCreatePlatformApplication_594163(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformApplication_594162(path: JsonNode; query: JsonNode;
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
  var valid_594164 = query.getOrDefault("Action")
  valid_594164 = validateParameter(valid_594164, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_594164 != nil:
    section.add "Action", valid_594164
  var valid_594165 = query.getOrDefault("Version")
  valid_594165 = validateParameter(valid_594165, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594165 != nil:
    section.add "Version", valid_594165
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
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Content-Sha256", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Algorithm")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Algorithm", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Signature")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Signature", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-SignedHeaders", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Credential")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Credential", valid_594172
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
  var valid_594173 = formData.getOrDefault("Name")
  valid_594173 = validateParameter(valid_594173, JString, required = true,
                                 default = nil)
  if valid_594173 != nil:
    section.add "Name", valid_594173
  var valid_594174 = formData.getOrDefault("Attributes.0.value")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "Attributes.0.value", valid_594174
  var valid_594175 = formData.getOrDefault("Attributes.0.key")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "Attributes.0.key", valid_594175
  var valid_594176 = formData.getOrDefault("Attributes.1.key")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "Attributes.1.key", valid_594176
  var valid_594177 = formData.getOrDefault("Attributes.2.value")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "Attributes.2.value", valid_594177
  var valid_594178 = formData.getOrDefault("Platform")
  valid_594178 = validateParameter(valid_594178, JString, required = true,
                                 default = nil)
  if valid_594178 != nil:
    section.add "Platform", valid_594178
  var valid_594179 = formData.getOrDefault("Attributes.2.key")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "Attributes.2.key", valid_594179
  var valid_594180 = formData.getOrDefault("Attributes.1.value")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "Attributes.1.value", valid_594180
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594181: Call_PostCreatePlatformApplication_594161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_594181.validator(path, query, header, formData, body)
  let scheme = call_594181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594181.url(scheme.get, call_594181.host, call_594181.base,
                         call_594181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594181, url, valid)

proc call*(call_594182: Call_PostCreatePlatformApplication_594161; Name: string;
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
  var query_594183 = newJObject()
  var formData_594184 = newJObject()
  add(formData_594184, "Name", newJString(Name))
  add(formData_594184, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_594184, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_594184, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594183, "Action", newJString(Action))
  add(formData_594184, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_594184, "Platform", newJString(Platform))
  add(formData_594184, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594183, "Version", newJString(Version))
  add(formData_594184, "Attributes.1.value", newJString(Attributes1Value))
  result = call_594182.call(nil, query_594183, nil, formData_594184, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_594161(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_594162, base: "/",
    url: url_PostCreatePlatformApplication_594163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_594138 = ref object of OpenApiRestCall_593437
proc url_GetCreatePlatformApplication_594140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformApplication_594139(path: JsonNode; query: JsonNode;
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
  var valid_594141 = query.getOrDefault("Attributes.2.key")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "Attributes.2.key", valid_594141
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_594142 = query.getOrDefault("Name")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = nil)
  if valid_594142 != nil:
    section.add "Name", valid_594142
  var valid_594143 = query.getOrDefault("Attributes.1.value")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "Attributes.1.value", valid_594143
  var valid_594144 = query.getOrDefault("Attributes.0.value")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "Attributes.0.value", valid_594144
  var valid_594145 = query.getOrDefault("Action")
  valid_594145 = validateParameter(valid_594145, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_594145 != nil:
    section.add "Action", valid_594145
  var valid_594146 = query.getOrDefault("Attributes.1.key")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "Attributes.1.key", valid_594146
  var valid_594147 = query.getOrDefault("Platform")
  valid_594147 = validateParameter(valid_594147, JString, required = true,
                                 default = nil)
  if valid_594147 != nil:
    section.add "Platform", valid_594147
  var valid_594148 = query.getOrDefault("Attributes.2.value")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "Attributes.2.value", valid_594148
  var valid_594149 = query.getOrDefault("Attributes.0.key")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "Attributes.0.key", valid_594149
  var valid_594150 = query.getOrDefault("Version")
  valid_594150 = validateParameter(valid_594150, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594150 != nil:
    section.add "Version", valid_594150
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
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Content-Sha256", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Algorithm")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Algorithm", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Signature")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Signature", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-SignedHeaders", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Credential")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Credential", valid_594157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594158: Call_GetCreatePlatformApplication_594138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_594158.validator(path, query, header, formData, body)
  let scheme = call_594158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594158.url(scheme.get, call_594158.host, call_594158.base,
                         call_594158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594158, url, valid)

proc call*(call_594159: Call_GetCreatePlatformApplication_594138; Name: string;
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
  var query_594160 = newJObject()
  add(query_594160, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594160, "Name", newJString(Name))
  add(query_594160, "Attributes.1.value", newJString(Attributes1Value))
  add(query_594160, "Attributes.0.value", newJString(Attributes0Value))
  add(query_594160, "Action", newJString(Action))
  add(query_594160, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594160, "Platform", newJString(Platform))
  add(query_594160, "Attributes.2.value", newJString(Attributes2Value))
  add(query_594160, "Attributes.0.key", newJString(Attributes0Key))
  add(query_594160, "Version", newJString(Version))
  result = call_594159.call(nil, query_594160, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_594138(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_594139, base: "/",
    url: url_GetCreatePlatformApplication_594140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_594209 = ref object of OpenApiRestCall_593437
proc url_PostCreatePlatformEndpoint_594211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformEndpoint_594210(path: JsonNode; query: JsonNode;
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
  var valid_594212 = query.getOrDefault("Action")
  valid_594212 = validateParameter(valid_594212, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_594212 != nil:
    section.add "Action", valid_594212
  var valid_594213 = query.getOrDefault("Version")
  valid_594213 = validateParameter(valid_594213, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594213 != nil:
    section.add "Version", valid_594213
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
  var valid_594214 = header.getOrDefault("X-Amz-Date")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Date", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Security-Token")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Security-Token", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Content-Sha256", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Algorithm")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Algorithm", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Signature")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Signature", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-SignedHeaders", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Credential")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Credential", valid_594220
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
  var valid_594221 = formData.getOrDefault("Attributes.0.value")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "Attributes.0.value", valid_594221
  var valid_594222 = formData.getOrDefault("Attributes.0.key")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "Attributes.0.key", valid_594222
  var valid_594223 = formData.getOrDefault("Attributes.1.key")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "Attributes.1.key", valid_594223
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_594224 = formData.getOrDefault("PlatformApplicationArn")
  valid_594224 = validateParameter(valid_594224, JString, required = true,
                                 default = nil)
  if valid_594224 != nil:
    section.add "PlatformApplicationArn", valid_594224
  var valid_594225 = formData.getOrDefault("CustomUserData")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "CustomUserData", valid_594225
  var valid_594226 = formData.getOrDefault("Attributes.2.value")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "Attributes.2.value", valid_594226
  var valid_594227 = formData.getOrDefault("Attributes.2.key")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "Attributes.2.key", valid_594227
  var valid_594228 = formData.getOrDefault("Attributes.1.value")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "Attributes.1.value", valid_594228
  var valid_594229 = formData.getOrDefault("Token")
  valid_594229 = validateParameter(valid_594229, JString, required = true,
                                 default = nil)
  if valid_594229 != nil:
    section.add "Token", valid_594229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594230: Call_PostCreatePlatformEndpoint_594209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_594230.validator(path, query, header, formData, body)
  let scheme = call_594230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594230.url(scheme.get, call_594230.host, call_594230.base,
                         call_594230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594230, url, valid)

proc call*(call_594231: Call_PostCreatePlatformEndpoint_594209;
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
  var query_594232 = newJObject()
  var formData_594233 = newJObject()
  add(formData_594233, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_594233, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_594233, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594232, "Action", newJString(Action))
  add(formData_594233, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_594233, "CustomUserData", newJString(CustomUserData))
  add(formData_594233, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_594233, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594232, "Version", newJString(Version))
  add(formData_594233, "Attributes.1.value", newJString(Attributes1Value))
  add(formData_594233, "Token", newJString(Token))
  result = call_594231.call(nil, query_594232, nil, formData_594233, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_594209(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_594210, base: "/",
    url: url_PostCreatePlatformEndpoint_594211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_594185 = ref object of OpenApiRestCall_593437
proc url_GetCreatePlatformEndpoint_594187(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformEndpoint_594186(path: JsonNode; query: JsonNode;
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
  var valid_594188 = query.getOrDefault("CustomUserData")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "CustomUserData", valid_594188
  var valid_594189 = query.getOrDefault("Attributes.2.key")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "Attributes.2.key", valid_594189
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_594190 = query.getOrDefault("Token")
  valid_594190 = validateParameter(valid_594190, JString, required = true,
                                 default = nil)
  if valid_594190 != nil:
    section.add "Token", valid_594190
  var valid_594191 = query.getOrDefault("Attributes.1.value")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "Attributes.1.value", valid_594191
  var valid_594192 = query.getOrDefault("Attributes.0.value")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "Attributes.0.value", valid_594192
  var valid_594193 = query.getOrDefault("Action")
  valid_594193 = validateParameter(valid_594193, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_594193 != nil:
    section.add "Action", valid_594193
  var valid_594194 = query.getOrDefault("Attributes.1.key")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "Attributes.1.key", valid_594194
  var valid_594195 = query.getOrDefault("Attributes.2.value")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "Attributes.2.value", valid_594195
  var valid_594196 = query.getOrDefault("Attributes.0.key")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "Attributes.0.key", valid_594196
  var valid_594197 = query.getOrDefault("Version")
  valid_594197 = validateParameter(valid_594197, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594197 != nil:
    section.add "Version", valid_594197
  var valid_594198 = query.getOrDefault("PlatformApplicationArn")
  valid_594198 = validateParameter(valid_594198, JString, required = true,
                                 default = nil)
  if valid_594198 != nil:
    section.add "PlatformApplicationArn", valid_594198
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
  var valid_594199 = header.getOrDefault("X-Amz-Date")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Date", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Security-Token")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Security-Token", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Content-Sha256", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Algorithm")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Algorithm", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Signature")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Signature", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-SignedHeaders", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-Credential")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Credential", valid_594205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594206: Call_GetCreatePlatformEndpoint_594185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_594206.validator(path, query, header, formData, body)
  let scheme = call_594206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594206.url(scheme.get, call_594206.host, call_594206.base,
                         call_594206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594206, url, valid)

proc call*(call_594207: Call_GetCreatePlatformEndpoint_594185; Token: string;
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
  var query_594208 = newJObject()
  add(query_594208, "CustomUserData", newJString(CustomUserData))
  add(query_594208, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594208, "Token", newJString(Token))
  add(query_594208, "Attributes.1.value", newJString(Attributes1Value))
  add(query_594208, "Attributes.0.value", newJString(Attributes0Value))
  add(query_594208, "Action", newJString(Action))
  add(query_594208, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594208, "Attributes.2.value", newJString(Attributes2Value))
  add(query_594208, "Attributes.0.key", newJString(Attributes0Key))
  add(query_594208, "Version", newJString(Version))
  add(query_594208, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_594207.call(nil, query_594208, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_594185(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_594186, base: "/",
    url: url_GetCreatePlatformEndpoint_594187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_594257 = ref object of OpenApiRestCall_593437
proc url_PostCreateTopic_594259(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateTopic_594258(path: JsonNode; query: JsonNode;
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
  var valid_594260 = query.getOrDefault("Action")
  valid_594260 = validateParameter(valid_594260, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_594260 != nil:
    section.add "Action", valid_594260
  var valid_594261 = query.getOrDefault("Version")
  valid_594261 = validateParameter(valid_594261, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594261 != nil:
    section.add "Version", valid_594261
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
  var valid_594262 = header.getOrDefault("X-Amz-Date")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Date", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Security-Token")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Security-Token", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Content-Sha256", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Algorithm")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Algorithm", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Signature")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Signature", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-SignedHeaders", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Credential")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Credential", valid_594268
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
  var valid_594269 = formData.getOrDefault("Name")
  valid_594269 = validateParameter(valid_594269, JString, required = true,
                                 default = nil)
  if valid_594269 != nil:
    section.add "Name", valid_594269
  var valid_594270 = formData.getOrDefault("Attributes.0.value")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "Attributes.0.value", valid_594270
  var valid_594271 = formData.getOrDefault("Attributes.0.key")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "Attributes.0.key", valid_594271
  var valid_594272 = formData.getOrDefault("Tags")
  valid_594272 = validateParameter(valid_594272, JArray, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "Tags", valid_594272
  var valid_594273 = formData.getOrDefault("Attributes.1.key")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "Attributes.1.key", valid_594273
  var valid_594274 = formData.getOrDefault("Attributes.2.value")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "Attributes.2.value", valid_594274
  var valid_594275 = formData.getOrDefault("Attributes.2.key")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "Attributes.2.key", valid_594275
  var valid_594276 = formData.getOrDefault("Attributes.1.value")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "Attributes.1.value", valid_594276
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594277: Call_PostCreateTopic_594257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_594277.validator(path, query, header, formData, body)
  let scheme = call_594277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594277.url(scheme.get, call_594277.host, call_594277.base,
                         call_594277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594277, url, valid)

proc call*(call_594278: Call_PostCreateTopic_594257; Name: string;
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
  var query_594279 = newJObject()
  var formData_594280 = newJObject()
  add(formData_594280, "Name", newJString(Name))
  add(formData_594280, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_594280, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    formData_594280.add "Tags", Tags
  add(formData_594280, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594279, "Action", newJString(Action))
  add(formData_594280, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_594280, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594279, "Version", newJString(Version))
  add(formData_594280, "Attributes.1.value", newJString(Attributes1Value))
  result = call_594278.call(nil, query_594279, nil, formData_594280, nil)

var postCreateTopic* = Call_PostCreateTopic_594257(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_594258,
    base: "/", url: url_PostCreateTopic_594259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_594234 = ref object of OpenApiRestCall_593437
proc url_GetCreateTopic_594236(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateTopic_594235(path: JsonNode; query: JsonNode;
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
  var valid_594237 = query.getOrDefault("Attributes.2.key")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "Attributes.2.key", valid_594237
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_594238 = query.getOrDefault("Name")
  valid_594238 = validateParameter(valid_594238, JString, required = true,
                                 default = nil)
  if valid_594238 != nil:
    section.add "Name", valid_594238
  var valid_594239 = query.getOrDefault("Attributes.1.value")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "Attributes.1.value", valid_594239
  var valid_594240 = query.getOrDefault("Tags")
  valid_594240 = validateParameter(valid_594240, JArray, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "Tags", valid_594240
  var valid_594241 = query.getOrDefault("Attributes.0.value")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "Attributes.0.value", valid_594241
  var valid_594242 = query.getOrDefault("Action")
  valid_594242 = validateParameter(valid_594242, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_594242 != nil:
    section.add "Action", valid_594242
  var valid_594243 = query.getOrDefault("Attributes.1.key")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "Attributes.1.key", valid_594243
  var valid_594244 = query.getOrDefault("Attributes.2.value")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "Attributes.2.value", valid_594244
  var valid_594245 = query.getOrDefault("Attributes.0.key")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "Attributes.0.key", valid_594245
  var valid_594246 = query.getOrDefault("Version")
  valid_594246 = validateParameter(valid_594246, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594246 != nil:
    section.add "Version", valid_594246
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
  var valid_594247 = header.getOrDefault("X-Amz-Date")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Date", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Security-Token")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Security-Token", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Content-Sha256", valid_594249
  var valid_594250 = header.getOrDefault("X-Amz-Algorithm")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Algorithm", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Signature")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Signature", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-SignedHeaders", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Credential")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Credential", valid_594253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594254: Call_GetCreateTopic_594234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_594254.validator(path, query, header, formData, body)
  let scheme = call_594254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594254.url(scheme.get, call_594254.host, call_594254.base,
                         call_594254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594254, url, valid)

proc call*(call_594255: Call_GetCreateTopic_594234; Name: string;
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
  var query_594256 = newJObject()
  add(query_594256, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594256, "Name", newJString(Name))
  add(query_594256, "Attributes.1.value", newJString(Attributes1Value))
  if Tags != nil:
    query_594256.add "Tags", Tags
  add(query_594256, "Attributes.0.value", newJString(Attributes0Value))
  add(query_594256, "Action", newJString(Action))
  add(query_594256, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594256, "Attributes.2.value", newJString(Attributes2Value))
  add(query_594256, "Attributes.0.key", newJString(Attributes0Key))
  add(query_594256, "Version", newJString(Version))
  result = call_594255.call(nil, query_594256, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_594234(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_594235,
    base: "/", url: url_GetCreateTopic_594236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_594297 = ref object of OpenApiRestCall_593437
proc url_PostDeleteEndpoint_594299(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEndpoint_594298(path: JsonNode; query: JsonNode;
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
  var valid_594300 = query.getOrDefault("Action")
  valid_594300 = validateParameter(valid_594300, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_594300 != nil:
    section.add "Action", valid_594300
  var valid_594301 = query.getOrDefault("Version")
  valid_594301 = validateParameter(valid_594301, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594301 != nil:
    section.add "Version", valid_594301
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
  var valid_594302 = header.getOrDefault("X-Amz-Date")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Date", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Security-Token")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Security-Token", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Content-Sha256", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Algorithm")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Algorithm", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Signature")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Signature", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Credential")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Credential", valid_594308
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_594309 = formData.getOrDefault("EndpointArn")
  valid_594309 = validateParameter(valid_594309, JString, required = true,
                                 default = nil)
  if valid_594309 != nil:
    section.add "EndpointArn", valid_594309
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594310: Call_PostDeleteEndpoint_594297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_594310.validator(path, query, header, formData, body)
  let scheme = call_594310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594310.url(scheme.get, call_594310.host, call_594310.base,
                         call_594310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594310, url, valid)

proc call*(call_594311: Call_PostDeleteEndpoint_594297; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_594312 = newJObject()
  var formData_594313 = newJObject()
  add(query_594312, "Action", newJString(Action))
  add(formData_594313, "EndpointArn", newJString(EndpointArn))
  add(query_594312, "Version", newJString(Version))
  result = call_594311.call(nil, query_594312, nil, formData_594313, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_594297(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_594298, base: "/",
    url: url_PostDeleteEndpoint_594299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_594281 = ref object of OpenApiRestCall_593437
proc url_GetDeleteEndpoint_594283(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEndpoint_594282(path: JsonNode; query: JsonNode;
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
  var valid_594284 = query.getOrDefault("EndpointArn")
  valid_594284 = validateParameter(valid_594284, JString, required = true,
                                 default = nil)
  if valid_594284 != nil:
    section.add "EndpointArn", valid_594284
  var valid_594285 = query.getOrDefault("Action")
  valid_594285 = validateParameter(valid_594285, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_594285 != nil:
    section.add "Action", valid_594285
  var valid_594286 = query.getOrDefault("Version")
  valid_594286 = validateParameter(valid_594286, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594286 != nil:
    section.add "Version", valid_594286
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
  var valid_594287 = header.getOrDefault("X-Amz-Date")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Date", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Security-Token")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Security-Token", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594294: Call_GetDeleteEndpoint_594281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_594294.validator(path, query, header, formData, body)
  let scheme = call_594294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594294.url(scheme.get, call_594294.host, call_594294.base,
                         call_594294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594294, url, valid)

proc call*(call_594295: Call_GetDeleteEndpoint_594281; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594296 = newJObject()
  add(query_594296, "EndpointArn", newJString(EndpointArn))
  add(query_594296, "Action", newJString(Action))
  add(query_594296, "Version", newJString(Version))
  result = call_594295.call(nil, query_594296, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_594281(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_594282,
    base: "/", url: url_GetDeleteEndpoint_594283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_594330 = ref object of OpenApiRestCall_593437
proc url_PostDeletePlatformApplication_594332(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeletePlatformApplication_594331(path: JsonNode; query: JsonNode;
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
  var valid_594333 = query.getOrDefault("Action")
  valid_594333 = validateParameter(valid_594333, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_594333 != nil:
    section.add "Action", valid_594333
  var valid_594334 = query.getOrDefault("Version")
  valid_594334 = validateParameter(valid_594334, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594334 != nil:
    section.add "Version", valid_594334
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
  var valid_594335 = header.getOrDefault("X-Amz-Date")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Date", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Security-Token")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Security-Token", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Content-Sha256", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Algorithm")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Algorithm", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Signature")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Signature", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-SignedHeaders", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Credential")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Credential", valid_594341
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_594342 = formData.getOrDefault("PlatformApplicationArn")
  valid_594342 = validateParameter(valid_594342, JString, required = true,
                                 default = nil)
  if valid_594342 != nil:
    section.add "PlatformApplicationArn", valid_594342
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594343: Call_PostDeletePlatformApplication_594330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_594343.validator(path, query, header, formData, body)
  let scheme = call_594343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594343.url(scheme.get, call_594343.host, call_594343.base,
                         call_594343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594343, url, valid)

proc call*(call_594344: Call_PostDeletePlatformApplication_594330;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Version: string (required)
  var query_594345 = newJObject()
  var formData_594346 = newJObject()
  add(query_594345, "Action", newJString(Action))
  add(formData_594346, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_594345, "Version", newJString(Version))
  result = call_594344.call(nil, query_594345, nil, formData_594346, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_594330(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_594331, base: "/",
    url: url_PostDeletePlatformApplication_594332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_594314 = ref object of OpenApiRestCall_593437
proc url_GetDeletePlatformApplication_594316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeletePlatformApplication_594315(path: JsonNode; query: JsonNode;
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
  var valid_594317 = query.getOrDefault("Action")
  valid_594317 = validateParameter(valid_594317, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_594317 != nil:
    section.add "Action", valid_594317
  var valid_594318 = query.getOrDefault("Version")
  valid_594318 = validateParameter(valid_594318, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594318 != nil:
    section.add "Version", valid_594318
  var valid_594319 = query.getOrDefault("PlatformApplicationArn")
  valid_594319 = validateParameter(valid_594319, JString, required = true,
                                 default = nil)
  if valid_594319 != nil:
    section.add "PlatformApplicationArn", valid_594319
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
  var valid_594320 = header.getOrDefault("X-Amz-Date")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Date", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Security-Token")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Security-Token", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Content-Sha256", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Algorithm")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Algorithm", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-Signature")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Signature", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-SignedHeaders", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-Credential")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Credential", valid_594326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594327: Call_GetDeletePlatformApplication_594314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_594327.validator(path, query, header, formData, body)
  let scheme = call_594327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594327.url(scheme.get, call_594327.host, call_594327.base,
                         call_594327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594327, url, valid)

proc call*(call_594328: Call_GetDeletePlatformApplication_594314;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  var query_594329 = newJObject()
  add(query_594329, "Action", newJString(Action))
  add(query_594329, "Version", newJString(Version))
  add(query_594329, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_594328.call(nil, query_594329, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_594314(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_594315, base: "/",
    url: url_GetDeletePlatformApplication_594316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_594363 = ref object of OpenApiRestCall_593437
proc url_PostDeleteTopic_594365(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteTopic_594364(path: JsonNode; query: JsonNode;
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
  var valid_594366 = query.getOrDefault("Action")
  valid_594366 = validateParameter(valid_594366, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_594366 != nil:
    section.add "Action", valid_594366
  var valid_594367 = query.getOrDefault("Version")
  valid_594367 = validateParameter(valid_594367, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594367 != nil:
    section.add "Version", valid_594367
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
  var valid_594368 = header.getOrDefault("X-Amz-Date")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Date", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Security-Token")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Security-Token", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Content-Sha256", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-Algorithm")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-Algorithm", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Signature")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Signature", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-SignedHeaders", valid_594373
  var valid_594374 = header.getOrDefault("X-Amz-Credential")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Credential", valid_594374
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_594375 = formData.getOrDefault("TopicArn")
  valid_594375 = validateParameter(valid_594375, JString, required = true,
                                 default = nil)
  if valid_594375 != nil:
    section.add "TopicArn", valid_594375
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594376: Call_PostDeleteTopic_594363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_594376.validator(path, query, header, formData, body)
  let scheme = call_594376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594376.url(scheme.get, call_594376.host, call_594376.base,
                         call_594376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594376, url, valid)

proc call*(call_594377: Call_PostDeleteTopic_594363; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594378 = newJObject()
  var formData_594379 = newJObject()
  add(formData_594379, "TopicArn", newJString(TopicArn))
  add(query_594378, "Action", newJString(Action))
  add(query_594378, "Version", newJString(Version))
  result = call_594377.call(nil, query_594378, nil, formData_594379, nil)

var postDeleteTopic* = Call_PostDeleteTopic_594363(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_594364,
    base: "/", url: url_PostDeleteTopic_594365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_594347 = ref object of OpenApiRestCall_593437
proc url_GetDeleteTopic_594349(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteTopic_594348(path: JsonNode; query: JsonNode;
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
  var valid_594350 = query.getOrDefault("Action")
  valid_594350 = validateParameter(valid_594350, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_594350 != nil:
    section.add "Action", valid_594350
  var valid_594351 = query.getOrDefault("TopicArn")
  valid_594351 = validateParameter(valid_594351, JString, required = true,
                                 default = nil)
  if valid_594351 != nil:
    section.add "TopicArn", valid_594351
  var valid_594352 = query.getOrDefault("Version")
  valid_594352 = validateParameter(valid_594352, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594352 != nil:
    section.add "Version", valid_594352
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
  var valid_594353 = header.getOrDefault("X-Amz-Date")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Date", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-Security-Token")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Security-Token", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Content-Sha256", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Algorithm")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Algorithm", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-Signature")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Signature", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-SignedHeaders", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Credential")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Credential", valid_594359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594360: Call_GetDeleteTopic_594347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_594360.validator(path, query, header, formData, body)
  let scheme = call_594360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594360.url(scheme.get, call_594360.host, call_594360.base,
                         call_594360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594360, url, valid)

proc call*(call_594361: Call_GetDeleteTopic_594347; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: string (required)
  var query_594362 = newJObject()
  add(query_594362, "Action", newJString(Action))
  add(query_594362, "TopicArn", newJString(TopicArn))
  add(query_594362, "Version", newJString(Version))
  result = call_594361.call(nil, query_594362, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_594347(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_594348,
    base: "/", url: url_GetDeleteTopic_594349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_594396 = ref object of OpenApiRestCall_593437
proc url_PostGetEndpointAttributes_594398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetEndpointAttributes_594397(path: JsonNode; query: JsonNode;
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
  var valid_594399 = query.getOrDefault("Action")
  valid_594399 = validateParameter(valid_594399, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_594399 != nil:
    section.add "Action", valid_594399
  var valid_594400 = query.getOrDefault("Version")
  valid_594400 = validateParameter(valid_594400, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594400 != nil:
    section.add "Version", valid_594400
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
  var valid_594401 = header.getOrDefault("X-Amz-Date")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-Date", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Security-Token")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Security-Token", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Content-Sha256", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Algorithm")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Algorithm", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-Signature")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Signature", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-SignedHeaders", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Credential")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Credential", valid_594407
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_594408 = formData.getOrDefault("EndpointArn")
  valid_594408 = validateParameter(valid_594408, JString, required = true,
                                 default = nil)
  if valid_594408 != nil:
    section.add "EndpointArn", valid_594408
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594409: Call_PostGetEndpointAttributes_594396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_594409.validator(path, query, header, formData, body)
  let scheme = call_594409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594409.url(scheme.get, call_594409.host, call_594409.base,
                         call_594409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594409, url, valid)

proc call*(call_594410: Call_PostGetEndpointAttributes_594396; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_594411 = newJObject()
  var formData_594412 = newJObject()
  add(query_594411, "Action", newJString(Action))
  add(formData_594412, "EndpointArn", newJString(EndpointArn))
  add(query_594411, "Version", newJString(Version))
  result = call_594410.call(nil, query_594411, nil, formData_594412, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_594396(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_594397, base: "/",
    url: url_PostGetEndpointAttributes_594398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_594380 = ref object of OpenApiRestCall_593437
proc url_GetGetEndpointAttributes_594382(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetEndpointAttributes_594381(path: JsonNode; query: JsonNode;
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
  var valid_594383 = query.getOrDefault("EndpointArn")
  valid_594383 = validateParameter(valid_594383, JString, required = true,
                                 default = nil)
  if valid_594383 != nil:
    section.add "EndpointArn", valid_594383
  var valid_594384 = query.getOrDefault("Action")
  valid_594384 = validateParameter(valid_594384, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_594384 != nil:
    section.add "Action", valid_594384
  var valid_594385 = query.getOrDefault("Version")
  valid_594385 = validateParameter(valid_594385, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594385 != nil:
    section.add "Version", valid_594385
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
  var valid_594386 = header.getOrDefault("X-Amz-Date")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-Date", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-Security-Token")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-Security-Token", valid_594387
  var valid_594388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "X-Amz-Content-Sha256", valid_594388
  var valid_594389 = header.getOrDefault("X-Amz-Algorithm")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Algorithm", valid_594389
  var valid_594390 = header.getOrDefault("X-Amz-Signature")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-Signature", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-SignedHeaders", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Credential")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Credential", valid_594392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594393: Call_GetGetEndpointAttributes_594380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_594393.validator(path, query, header, formData, body)
  let scheme = call_594393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594393.url(scheme.get, call_594393.host, call_594393.base,
                         call_594393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594393, url, valid)

proc call*(call_594394: Call_GetGetEndpointAttributes_594380; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594395 = newJObject()
  add(query_594395, "EndpointArn", newJString(EndpointArn))
  add(query_594395, "Action", newJString(Action))
  add(query_594395, "Version", newJString(Version))
  result = call_594394.call(nil, query_594395, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_594380(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_594381, base: "/",
    url: url_GetGetEndpointAttributes_594382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_594429 = ref object of OpenApiRestCall_593437
proc url_PostGetPlatformApplicationAttributes_594431(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetPlatformApplicationAttributes_594430(path: JsonNode;
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
  var valid_594432 = query.getOrDefault("Action")
  valid_594432 = validateParameter(valid_594432, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_594432 != nil:
    section.add "Action", valid_594432
  var valid_594433 = query.getOrDefault("Version")
  valid_594433 = validateParameter(valid_594433, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594433 != nil:
    section.add "Version", valid_594433
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
  var valid_594434 = header.getOrDefault("X-Amz-Date")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Date", valid_594434
  var valid_594435 = header.getOrDefault("X-Amz-Security-Token")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-Security-Token", valid_594435
  var valid_594436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Content-Sha256", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Algorithm")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Algorithm", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Signature")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Signature", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-SignedHeaders", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Credential")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Credential", valid_594440
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_594441 = formData.getOrDefault("PlatformApplicationArn")
  valid_594441 = validateParameter(valid_594441, JString, required = true,
                                 default = nil)
  if valid_594441 != nil:
    section.add "PlatformApplicationArn", valid_594441
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594442: Call_PostGetPlatformApplicationAttributes_594429;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_594442.validator(path, query, header, formData, body)
  let scheme = call_594442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594442.url(scheme.get, call_594442.host, call_594442.base,
                         call_594442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594442, url, valid)

proc call*(call_594443: Call_PostGetPlatformApplicationAttributes_594429;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Version: string (required)
  var query_594444 = newJObject()
  var formData_594445 = newJObject()
  add(query_594444, "Action", newJString(Action))
  add(formData_594445, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_594444, "Version", newJString(Version))
  result = call_594443.call(nil, query_594444, nil, formData_594445, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_594429(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_594430, base: "/",
    url: url_PostGetPlatformApplicationAttributes_594431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_594413 = ref object of OpenApiRestCall_593437
proc url_GetGetPlatformApplicationAttributes_594415(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetPlatformApplicationAttributes_594414(path: JsonNode;
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
  var valid_594416 = query.getOrDefault("Action")
  valid_594416 = validateParameter(valid_594416, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_594416 != nil:
    section.add "Action", valid_594416
  var valid_594417 = query.getOrDefault("Version")
  valid_594417 = validateParameter(valid_594417, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594417 != nil:
    section.add "Version", valid_594417
  var valid_594418 = query.getOrDefault("PlatformApplicationArn")
  valid_594418 = validateParameter(valid_594418, JString, required = true,
                                 default = nil)
  if valid_594418 != nil:
    section.add "PlatformApplicationArn", valid_594418
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
  var valid_594419 = header.getOrDefault("X-Amz-Date")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Date", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-Security-Token")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-Security-Token", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Content-Sha256", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Algorithm")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Algorithm", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Signature")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Signature", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-SignedHeaders", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Credential")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Credential", valid_594425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594426: Call_GetGetPlatformApplicationAttributes_594413;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_594426.validator(path, query, header, formData, body)
  let scheme = call_594426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594426.url(scheme.get, call_594426.host, call_594426.base,
                         call_594426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594426, url, valid)

proc call*(call_594427: Call_GetGetPlatformApplicationAttributes_594413;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  var query_594428 = newJObject()
  add(query_594428, "Action", newJString(Action))
  add(query_594428, "Version", newJString(Version))
  add(query_594428, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_594427.call(nil, query_594428, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_594413(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_594414, base: "/",
    url: url_GetGetPlatformApplicationAttributes_594415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_594462 = ref object of OpenApiRestCall_593437
proc url_PostGetSMSAttributes_594464(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetSMSAttributes_594463(path: JsonNode; query: JsonNode;
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
  var valid_594465 = query.getOrDefault("Action")
  valid_594465 = validateParameter(valid_594465, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_594465 != nil:
    section.add "Action", valid_594465
  var valid_594466 = query.getOrDefault("Version")
  valid_594466 = validateParameter(valid_594466, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594466 != nil:
    section.add "Version", valid_594466
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
  var valid_594467 = header.getOrDefault("X-Amz-Date")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Date", valid_594467
  var valid_594468 = header.getOrDefault("X-Amz-Security-Token")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-Security-Token", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Content-Sha256", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-Algorithm")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Algorithm", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Signature")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Signature", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-SignedHeaders", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Credential")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Credential", valid_594473
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_594474 = formData.getOrDefault("attributes")
  valid_594474 = validateParameter(valid_594474, JArray, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "attributes", valid_594474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594475: Call_PostGetSMSAttributes_594462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_594475.validator(path, query, header, formData, body)
  let scheme = call_594475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594475.url(scheme.get, call_594475.host, call_594475.base,
                         call_594475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594475, url, valid)

proc call*(call_594476: Call_PostGetSMSAttributes_594462;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594477 = newJObject()
  var formData_594478 = newJObject()
  if attributes != nil:
    formData_594478.add "attributes", attributes
  add(query_594477, "Action", newJString(Action))
  add(query_594477, "Version", newJString(Version))
  result = call_594476.call(nil, query_594477, nil, formData_594478, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_594462(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_594463, base: "/",
    url: url_PostGetSMSAttributes_594464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_594446 = ref object of OpenApiRestCall_593437
proc url_GetGetSMSAttributes_594448(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetSMSAttributes_594447(path: JsonNode; query: JsonNode;
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
  var valid_594449 = query.getOrDefault("attributes")
  valid_594449 = validateParameter(valid_594449, JArray, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "attributes", valid_594449
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594450 = query.getOrDefault("Action")
  valid_594450 = validateParameter(valid_594450, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_594450 != nil:
    section.add "Action", valid_594450
  var valid_594451 = query.getOrDefault("Version")
  valid_594451 = validateParameter(valid_594451, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594451 != nil:
    section.add "Version", valid_594451
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
  var valid_594452 = header.getOrDefault("X-Amz-Date")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Date", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-Security-Token")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-Security-Token", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Content-Sha256", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Algorithm")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Algorithm", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Signature")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Signature", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-SignedHeaders", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Credential")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Credential", valid_594458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594459: Call_GetGetSMSAttributes_594446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_594459.validator(path, query, header, formData, body)
  let scheme = call_594459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594459.url(scheme.get, call_594459.host, call_594459.base,
                         call_594459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594459, url, valid)

proc call*(call_594460: Call_GetGetSMSAttributes_594446;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594461 = newJObject()
  if attributes != nil:
    query_594461.add "attributes", attributes
  add(query_594461, "Action", newJString(Action))
  add(query_594461, "Version", newJString(Version))
  result = call_594460.call(nil, query_594461, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_594446(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_594447, base: "/",
    url: url_GetGetSMSAttributes_594448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_594495 = ref object of OpenApiRestCall_593437
proc url_PostGetSubscriptionAttributes_594497(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetSubscriptionAttributes_594496(path: JsonNode; query: JsonNode;
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
  var valid_594498 = query.getOrDefault("Action")
  valid_594498 = validateParameter(valid_594498, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_594498 != nil:
    section.add "Action", valid_594498
  var valid_594499 = query.getOrDefault("Version")
  valid_594499 = validateParameter(valid_594499, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594499 != nil:
    section.add "Version", valid_594499
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
  var valid_594500 = header.getOrDefault("X-Amz-Date")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Date", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Security-Token")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Security-Token", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Content-Sha256", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Algorithm")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Algorithm", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Signature")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Signature", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-SignedHeaders", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Credential")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Credential", valid_594506
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_594507 = formData.getOrDefault("SubscriptionArn")
  valid_594507 = validateParameter(valid_594507, JString, required = true,
                                 default = nil)
  if valid_594507 != nil:
    section.add "SubscriptionArn", valid_594507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594508: Call_PostGetSubscriptionAttributes_594495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_594508.validator(path, query, header, formData, body)
  let scheme = call_594508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594508.url(scheme.get, call_594508.host, call_594508.base,
                         call_594508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594508, url, valid)

proc call*(call_594509: Call_PostGetSubscriptionAttributes_594495;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Version: string (required)
  var query_594510 = newJObject()
  var formData_594511 = newJObject()
  add(query_594510, "Action", newJString(Action))
  add(formData_594511, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_594510, "Version", newJString(Version))
  result = call_594509.call(nil, query_594510, nil, formData_594511, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_594495(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_594496, base: "/",
    url: url_PostGetSubscriptionAttributes_594497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_594479 = ref object of OpenApiRestCall_593437
proc url_GetGetSubscriptionAttributes_594481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetSubscriptionAttributes_594480(path: JsonNode; query: JsonNode;
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
  var valid_594482 = query.getOrDefault("SubscriptionArn")
  valid_594482 = validateParameter(valid_594482, JString, required = true,
                                 default = nil)
  if valid_594482 != nil:
    section.add "SubscriptionArn", valid_594482
  var valid_594483 = query.getOrDefault("Action")
  valid_594483 = validateParameter(valid_594483, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_594483 != nil:
    section.add "Action", valid_594483
  var valid_594484 = query.getOrDefault("Version")
  valid_594484 = validateParameter(valid_594484, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594484 != nil:
    section.add "Version", valid_594484
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
  var valid_594485 = header.getOrDefault("X-Amz-Date")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Date", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Security-Token")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Security-Token", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Content-Sha256", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Algorithm")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Algorithm", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Signature")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Signature", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-SignedHeaders", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Credential")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Credential", valid_594491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594492: Call_GetGetSubscriptionAttributes_594479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_594492.validator(path, query, header, formData, body)
  let scheme = call_594492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594492.url(scheme.get, call_594492.host, call_594492.base,
                         call_594492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594492, url, valid)

proc call*(call_594493: Call_GetGetSubscriptionAttributes_594479;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594494 = newJObject()
  add(query_594494, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_594494, "Action", newJString(Action))
  add(query_594494, "Version", newJString(Version))
  result = call_594493.call(nil, query_594494, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_594479(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_594480, base: "/",
    url: url_GetGetSubscriptionAttributes_594481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_594528 = ref object of OpenApiRestCall_593437
proc url_PostGetTopicAttributes_594530(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetTopicAttributes_594529(path: JsonNode; query: JsonNode;
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
  var valid_594531 = query.getOrDefault("Action")
  valid_594531 = validateParameter(valid_594531, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_594531 != nil:
    section.add "Action", valid_594531
  var valid_594532 = query.getOrDefault("Version")
  valid_594532 = validateParameter(valid_594532, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594532 != nil:
    section.add "Version", valid_594532
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
  var valid_594533 = header.getOrDefault("X-Amz-Date")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Date", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Security-Token")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Security-Token", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Content-Sha256", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Algorithm")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Algorithm", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Signature")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Signature", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-SignedHeaders", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Credential")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Credential", valid_594539
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_594540 = formData.getOrDefault("TopicArn")
  valid_594540 = validateParameter(valid_594540, JString, required = true,
                                 default = nil)
  if valid_594540 != nil:
    section.add "TopicArn", valid_594540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594541: Call_PostGetTopicAttributes_594528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_594541.validator(path, query, header, formData, body)
  let scheme = call_594541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594541.url(scheme.get, call_594541.host, call_594541.base,
                         call_594541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594541, url, valid)

proc call*(call_594542: Call_PostGetTopicAttributes_594528; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594543 = newJObject()
  var formData_594544 = newJObject()
  add(formData_594544, "TopicArn", newJString(TopicArn))
  add(query_594543, "Action", newJString(Action))
  add(query_594543, "Version", newJString(Version))
  result = call_594542.call(nil, query_594543, nil, formData_594544, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_594528(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_594529, base: "/",
    url: url_PostGetTopicAttributes_594530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_594512 = ref object of OpenApiRestCall_593437
proc url_GetGetTopicAttributes_594514(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetTopicAttributes_594513(path: JsonNode; query: JsonNode;
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
  var valid_594515 = query.getOrDefault("Action")
  valid_594515 = validateParameter(valid_594515, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_594515 != nil:
    section.add "Action", valid_594515
  var valid_594516 = query.getOrDefault("TopicArn")
  valid_594516 = validateParameter(valid_594516, JString, required = true,
                                 default = nil)
  if valid_594516 != nil:
    section.add "TopicArn", valid_594516
  var valid_594517 = query.getOrDefault("Version")
  valid_594517 = validateParameter(valid_594517, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594517 != nil:
    section.add "Version", valid_594517
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
  var valid_594518 = header.getOrDefault("X-Amz-Date")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Date", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Security-Token")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Security-Token", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Content-Sha256", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Algorithm")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Algorithm", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Signature")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Signature", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-SignedHeaders", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Credential")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Credential", valid_594524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594525: Call_GetGetTopicAttributes_594512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_594525.validator(path, query, header, formData, body)
  let scheme = call_594525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594525.url(scheme.get, call_594525.host, call_594525.base,
                         call_594525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594525, url, valid)

proc call*(call_594526: Call_GetGetTopicAttributes_594512; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: string (required)
  var query_594527 = newJObject()
  add(query_594527, "Action", newJString(Action))
  add(query_594527, "TopicArn", newJString(TopicArn))
  add(query_594527, "Version", newJString(Version))
  result = call_594526.call(nil, query_594527, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_594512(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_594513, base: "/",
    url: url_GetGetTopicAttributes_594514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_594562 = ref object of OpenApiRestCall_593437
proc url_PostListEndpointsByPlatformApplication_594564(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListEndpointsByPlatformApplication_594563(path: JsonNode;
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
  var valid_594565 = query.getOrDefault("Action")
  valid_594565 = validateParameter(valid_594565, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_594565 != nil:
    section.add "Action", valid_594565
  var valid_594566 = query.getOrDefault("Version")
  valid_594566 = validateParameter(valid_594566, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594566 != nil:
    section.add "Version", valid_594566
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
  var valid_594567 = header.getOrDefault("X-Amz-Date")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Date", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-Security-Token")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Security-Token", valid_594568
  var valid_594569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Content-Sha256", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Algorithm")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Algorithm", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-Signature")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Signature", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-SignedHeaders", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-Credential")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-Credential", valid_594573
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_594574 = formData.getOrDefault("NextToken")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "NextToken", valid_594574
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_594575 = formData.getOrDefault("PlatformApplicationArn")
  valid_594575 = validateParameter(valid_594575, JString, required = true,
                                 default = nil)
  if valid_594575 != nil:
    section.add "PlatformApplicationArn", valid_594575
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594576: Call_PostListEndpointsByPlatformApplication_594562;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_594576.validator(path, query, header, formData, body)
  let scheme = call_594576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594576.url(scheme.get, call_594576.host, call_594576.base,
                         call_594576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594576, url, valid)

proc call*(call_594577: Call_PostListEndpointsByPlatformApplication_594562;
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
  var query_594578 = newJObject()
  var formData_594579 = newJObject()
  add(formData_594579, "NextToken", newJString(NextToken))
  add(query_594578, "Action", newJString(Action))
  add(formData_594579, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_594578, "Version", newJString(Version))
  result = call_594577.call(nil, query_594578, nil, formData_594579, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_594562(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_594563, base: "/",
    url: url_PostListEndpointsByPlatformApplication_594564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_594545 = ref object of OpenApiRestCall_593437
proc url_GetListEndpointsByPlatformApplication_594547(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListEndpointsByPlatformApplication_594546(path: JsonNode;
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
  var valid_594548 = query.getOrDefault("NextToken")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "NextToken", valid_594548
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594549 = query.getOrDefault("Action")
  valid_594549 = validateParameter(valid_594549, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_594549 != nil:
    section.add "Action", valid_594549
  var valid_594550 = query.getOrDefault("Version")
  valid_594550 = validateParameter(valid_594550, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594550 != nil:
    section.add "Version", valid_594550
  var valid_594551 = query.getOrDefault("PlatformApplicationArn")
  valid_594551 = validateParameter(valid_594551, JString, required = true,
                                 default = nil)
  if valid_594551 != nil:
    section.add "PlatformApplicationArn", valid_594551
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
  var valid_594552 = header.getOrDefault("X-Amz-Date")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Date", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Security-Token")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Security-Token", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Content-Sha256", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Algorithm")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Algorithm", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Signature")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Signature", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-SignedHeaders", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-Credential")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-Credential", valid_594558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594559: Call_GetListEndpointsByPlatformApplication_594545;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_594559.validator(path, query, header, formData, body)
  let scheme = call_594559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594559.url(scheme.get, call_594559.host, call_594559.base,
                         call_594559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594559, url, valid)

proc call*(call_594560: Call_GetListEndpointsByPlatformApplication_594545;
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
  var query_594561 = newJObject()
  add(query_594561, "NextToken", newJString(NextToken))
  add(query_594561, "Action", newJString(Action))
  add(query_594561, "Version", newJString(Version))
  add(query_594561, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_594560.call(nil, query_594561, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_594545(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_594546, base: "/",
    url: url_GetListEndpointsByPlatformApplication_594547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_594596 = ref object of OpenApiRestCall_593437
proc url_PostListPhoneNumbersOptedOut_594598(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPhoneNumbersOptedOut_594597(path: JsonNode; query: JsonNode;
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
  var valid_594599 = query.getOrDefault("Action")
  valid_594599 = validateParameter(valid_594599, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_594599 != nil:
    section.add "Action", valid_594599
  var valid_594600 = query.getOrDefault("Version")
  valid_594600 = validateParameter(valid_594600, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594600 != nil:
    section.add "Version", valid_594600
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
  var valid_594601 = header.getOrDefault("X-Amz-Date")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Date", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Security-Token")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Security-Token", valid_594602
  var valid_594603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "X-Amz-Content-Sha256", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Algorithm")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Algorithm", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Signature")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Signature", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-SignedHeaders", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Credential")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Credential", valid_594607
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_594608 = formData.getOrDefault("nextToken")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "nextToken", valid_594608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594609: Call_PostListPhoneNumbersOptedOut_594596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_594609.validator(path, query, header, formData, body)
  let scheme = call_594609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594609.url(scheme.get, call_594609.host, call_594609.base,
                         call_594609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594609, url, valid)

proc call*(call_594610: Call_PostListPhoneNumbersOptedOut_594596;
          Action: string = "ListPhoneNumbersOptedOut"; nextToken: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   Action: string (required)
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Version: string (required)
  var query_594611 = newJObject()
  var formData_594612 = newJObject()
  add(query_594611, "Action", newJString(Action))
  add(formData_594612, "nextToken", newJString(nextToken))
  add(query_594611, "Version", newJString(Version))
  result = call_594610.call(nil, query_594611, nil, formData_594612, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_594596(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_594597, base: "/",
    url: url_PostListPhoneNumbersOptedOut_594598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_594580 = ref object of OpenApiRestCall_593437
proc url_GetListPhoneNumbersOptedOut_594582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPhoneNumbersOptedOut_594581(path: JsonNode; query: JsonNode;
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
  var valid_594583 = query.getOrDefault("nextToken")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "nextToken", valid_594583
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594584 = query.getOrDefault("Action")
  valid_594584 = validateParameter(valid_594584, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_594584 != nil:
    section.add "Action", valid_594584
  var valid_594585 = query.getOrDefault("Version")
  valid_594585 = validateParameter(valid_594585, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594585 != nil:
    section.add "Version", valid_594585
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
  var valid_594586 = header.getOrDefault("X-Amz-Date")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Date", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-Security-Token")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Security-Token", valid_594587
  var valid_594588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "X-Amz-Content-Sha256", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Algorithm")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Algorithm", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Signature")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Signature", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-SignedHeaders", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Credential")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Credential", valid_594592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594593: Call_GetListPhoneNumbersOptedOut_594580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_594593.validator(path, query, header, formData, body)
  let scheme = call_594593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594593.url(scheme.get, call_594593.host, call_594593.base,
                         call_594593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594593, url, valid)

proc call*(call_594594: Call_GetListPhoneNumbersOptedOut_594580;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594595 = newJObject()
  add(query_594595, "nextToken", newJString(nextToken))
  add(query_594595, "Action", newJString(Action))
  add(query_594595, "Version", newJString(Version))
  result = call_594594.call(nil, query_594595, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_594580(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_594581, base: "/",
    url: url_GetListPhoneNumbersOptedOut_594582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_594629 = ref object of OpenApiRestCall_593437
proc url_PostListPlatformApplications_594631(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPlatformApplications_594630(path: JsonNode; query: JsonNode;
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
  var valid_594632 = query.getOrDefault("Action")
  valid_594632 = validateParameter(valid_594632, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_594632 != nil:
    section.add "Action", valid_594632
  var valid_594633 = query.getOrDefault("Version")
  valid_594633 = validateParameter(valid_594633, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594633 != nil:
    section.add "Version", valid_594633
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
  var valid_594634 = header.getOrDefault("X-Amz-Date")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Date", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-Security-Token")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Security-Token", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Content-Sha256", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-Algorithm")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Algorithm", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Signature")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Signature", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-SignedHeaders", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Credential")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Credential", valid_594640
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_594641 = formData.getOrDefault("NextToken")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "NextToken", valid_594641
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594642: Call_PostListPlatformApplications_594629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_594642.validator(path, query, header, formData, body)
  let scheme = call_594642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594642.url(scheme.get, call_594642.host, call_594642.base,
                         call_594642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594642, url, valid)

proc call*(call_594643: Call_PostListPlatformApplications_594629;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594644 = newJObject()
  var formData_594645 = newJObject()
  add(formData_594645, "NextToken", newJString(NextToken))
  add(query_594644, "Action", newJString(Action))
  add(query_594644, "Version", newJString(Version))
  result = call_594643.call(nil, query_594644, nil, formData_594645, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_594629(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_594630, base: "/",
    url: url_PostListPlatformApplications_594631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_594613 = ref object of OpenApiRestCall_593437
proc url_GetListPlatformApplications_594615(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPlatformApplications_594614(path: JsonNode; query: JsonNode;
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
  var valid_594616 = query.getOrDefault("NextToken")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "NextToken", valid_594616
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594617 = query.getOrDefault("Action")
  valid_594617 = validateParameter(valid_594617, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_594617 != nil:
    section.add "Action", valid_594617
  var valid_594618 = query.getOrDefault("Version")
  valid_594618 = validateParameter(valid_594618, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594618 != nil:
    section.add "Version", valid_594618
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
  var valid_594619 = header.getOrDefault("X-Amz-Date")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Date", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-Security-Token")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-Security-Token", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Content-Sha256", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-Algorithm")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Algorithm", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Signature")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Signature", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-SignedHeaders", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Credential")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Credential", valid_594625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594626: Call_GetListPlatformApplications_594613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_594626.validator(path, query, header, formData, body)
  let scheme = call_594626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594626.url(scheme.get, call_594626.host, call_594626.base,
                         call_594626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594626, url, valid)

proc call*(call_594627: Call_GetListPlatformApplications_594613;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594628 = newJObject()
  add(query_594628, "NextToken", newJString(NextToken))
  add(query_594628, "Action", newJString(Action))
  add(query_594628, "Version", newJString(Version))
  result = call_594627.call(nil, query_594628, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_594613(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_594614, base: "/",
    url: url_GetListPlatformApplications_594615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_594662 = ref object of OpenApiRestCall_593437
proc url_PostListSubscriptions_594664(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListSubscriptions_594663(path: JsonNode; query: JsonNode;
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
  var valid_594665 = query.getOrDefault("Action")
  valid_594665 = validateParameter(valid_594665, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_594665 != nil:
    section.add "Action", valid_594665
  var valid_594666 = query.getOrDefault("Version")
  valid_594666 = validateParameter(valid_594666, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594666 != nil:
    section.add "Version", valid_594666
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
  var valid_594667 = header.getOrDefault("X-Amz-Date")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Date", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Security-Token")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Security-Token", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Content-Sha256", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-Algorithm")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Algorithm", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Signature")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Signature", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-SignedHeaders", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-Credential")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Credential", valid_594673
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_594674 = formData.getOrDefault("NextToken")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "NextToken", valid_594674
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594675: Call_PostListSubscriptions_594662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_594675.validator(path, query, header, formData, body)
  let scheme = call_594675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594675.url(scheme.get, call_594675.host, call_594675.base,
                         call_594675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594675, url, valid)

proc call*(call_594676: Call_PostListSubscriptions_594662; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594677 = newJObject()
  var formData_594678 = newJObject()
  add(formData_594678, "NextToken", newJString(NextToken))
  add(query_594677, "Action", newJString(Action))
  add(query_594677, "Version", newJString(Version))
  result = call_594676.call(nil, query_594677, nil, formData_594678, nil)

var postListSubscriptions* = Call_PostListSubscriptions_594662(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_594663, base: "/",
    url: url_PostListSubscriptions_594664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_594646 = ref object of OpenApiRestCall_593437
proc url_GetListSubscriptions_594648(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListSubscriptions_594647(path: JsonNode; query: JsonNode;
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
  var valid_594649 = query.getOrDefault("NextToken")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "NextToken", valid_594649
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594650 = query.getOrDefault("Action")
  valid_594650 = validateParameter(valid_594650, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_594650 != nil:
    section.add "Action", valid_594650
  var valid_594651 = query.getOrDefault("Version")
  valid_594651 = validateParameter(valid_594651, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594651 != nil:
    section.add "Version", valid_594651
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
  var valid_594652 = header.getOrDefault("X-Amz-Date")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-Date", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Security-Token")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Security-Token", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Content-Sha256", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Algorithm")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Algorithm", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Signature")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Signature", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-SignedHeaders", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-Credential")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Credential", valid_594658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594659: Call_GetListSubscriptions_594646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_594659.validator(path, query, header, formData, body)
  let scheme = call_594659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594659.url(scheme.get, call_594659.host, call_594659.base,
                         call_594659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594659, url, valid)

proc call*(call_594660: Call_GetListSubscriptions_594646; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594661 = newJObject()
  add(query_594661, "NextToken", newJString(NextToken))
  add(query_594661, "Action", newJString(Action))
  add(query_594661, "Version", newJString(Version))
  result = call_594660.call(nil, query_594661, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_594646(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_594647, base: "/",
    url: url_GetListSubscriptions_594648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_594696 = ref object of OpenApiRestCall_593437
proc url_PostListSubscriptionsByTopic_594698(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListSubscriptionsByTopic_594697(path: JsonNode; query: JsonNode;
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
  var valid_594699 = query.getOrDefault("Action")
  valid_594699 = validateParameter(valid_594699, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_594699 != nil:
    section.add "Action", valid_594699
  var valid_594700 = query.getOrDefault("Version")
  valid_594700 = validateParameter(valid_594700, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594700 != nil:
    section.add "Version", valid_594700
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
  var valid_594701 = header.getOrDefault("X-Amz-Date")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Date", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-Security-Token")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Security-Token", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Content-Sha256", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-Algorithm")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-Algorithm", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Signature")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Signature", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-SignedHeaders", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Credential")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Credential", valid_594707
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_594708 = formData.getOrDefault("NextToken")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "NextToken", valid_594708
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_594709 = formData.getOrDefault("TopicArn")
  valid_594709 = validateParameter(valid_594709, JString, required = true,
                                 default = nil)
  if valid_594709 != nil:
    section.add "TopicArn", valid_594709
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594710: Call_PostListSubscriptionsByTopic_594696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_594710.validator(path, query, header, formData, body)
  let scheme = call_594710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594710.url(scheme.get, call_594710.host, call_594710.base,
                         call_594710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594710, url, valid)

proc call*(call_594711: Call_PostListSubscriptionsByTopic_594696; TopicArn: string;
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
  var query_594712 = newJObject()
  var formData_594713 = newJObject()
  add(formData_594713, "NextToken", newJString(NextToken))
  add(formData_594713, "TopicArn", newJString(TopicArn))
  add(query_594712, "Action", newJString(Action))
  add(query_594712, "Version", newJString(Version))
  result = call_594711.call(nil, query_594712, nil, formData_594713, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_594696(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_594697, base: "/",
    url: url_PostListSubscriptionsByTopic_594698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_594679 = ref object of OpenApiRestCall_593437
proc url_GetListSubscriptionsByTopic_594681(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListSubscriptionsByTopic_594680(path: JsonNode; query: JsonNode;
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
  var valid_594682 = query.getOrDefault("NextToken")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "NextToken", valid_594682
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594683 = query.getOrDefault("Action")
  valid_594683 = validateParameter(valid_594683, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_594683 != nil:
    section.add "Action", valid_594683
  var valid_594684 = query.getOrDefault("TopicArn")
  valid_594684 = validateParameter(valid_594684, JString, required = true,
                                 default = nil)
  if valid_594684 != nil:
    section.add "TopicArn", valid_594684
  var valid_594685 = query.getOrDefault("Version")
  valid_594685 = validateParameter(valid_594685, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594685 != nil:
    section.add "Version", valid_594685
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
  var valid_594686 = header.getOrDefault("X-Amz-Date")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-Date", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-Security-Token")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Security-Token", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Content-Sha256", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-Algorithm")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-Algorithm", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Signature")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Signature", valid_594690
  var valid_594691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-SignedHeaders", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-Credential")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Credential", valid_594692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594693: Call_GetListSubscriptionsByTopic_594679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_594693.validator(path, query, header, formData, body)
  let scheme = call_594693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594693.url(scheme.get, call_594693.host, call_594693.base,
                         call_594693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594693, url, valid)

proc call*(call_594694: Call_GetListSubscriptionsByTopic_594679; TopicArn: string;
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
  var query_594695 = newJObject()
  add(query_594695, "NextToken", newJString(NextToken))
  add(query_594695, "Action", newJString(Action))
  add(query_594695, "TopicArn", newJString(TopicArn))
  add(query_594695, "Version", newJString(Version))
  result = call_594694.call(nil, query_594695, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_594679(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_594680, base: "/",
    url: url_GetListSubscriptionsByTopic_594681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_594730 = ref object of OpenApiRestCall_593437
proc url_PostListTagsForResource_594732(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_594731(path: JsonNode; query: JsonNode;
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
  var valid_594733 = query.getOrDefault("Action")
  valid_594733 = validateParameter(valid_594733, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594733 != nil:
    section.add "Action", valid_594733
  var valid_594734 = query.getOrDefault("Version")
  valid_594734 = validateParameter(valid_594734, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594734 != nil:
    section.add "Version", valid_594734
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
  var valid_594735 = header.getOrDefault("X-Amz-Date")
  valid_594735 = validateParameter(valid_594735, JString, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "X-Amz-Date", valid_594735
  var valid_594736 = header.getOrDefault("X-Amz-Security-Token")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Security-Token", valid_594736
  var valid_594737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Content-Sha256", valid_594737
  var valid_594738 = header.getOrDefault("X-Amz-Algorithm")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "X-Amz-Algorithm", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Signature")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Signature", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-SignedHeaders", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Credential")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Credential", valid_594741
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_594742 = formData.getOrDefault("ResourceArn")
  valid_594742 = validateParameter(valid_594742, JString, required = true,
                                 default = nil)
  if valid_594742 != nil:
    section.add "ResourceArn", valid_594742
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594743: Call_PostListTagsForResource_594730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_594743.validator(path, query, header, formData, body)
  let scheme = call_594743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594743.url(scheme.get, call_594743.host, call_594743.base,
                         call_594743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594743, url, valid)

proc call*(call_594744: Call_PostListTagsForResource_594730; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Version: string (required)
  var query_594745 = newJObject()
  var formData_594746 = newJObject()
  add(query_594745, "Action", newJString(Action))
  add(formData_594746, "ResourceArn", newJString(ResourceArn))
  add(query_594745, "Version", newJString(Version))
  result = call_594744.call(nil, query_594745, nil, formData_594746, nil)

var postListTagsForResource* = Call_PostListTagsForResource_594730(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_594731, base: "/",
    url: url_PostListTagsForResource_594732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_594714 = ref object of OpenApiRestCall_593437
proc url_GetListTagsForResource_594716(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_594715(path: JsonNode; query: JsonNode;
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
  var valid_594717 = query.getOrDefault("ResourceArn")
  valid_594717 = validateParameter(valid_594717, JString, required = true,
                                 default = nil)
  if valid_594717 != nil:
    section.add "ResourceArn", valid_594717
  var valid_594718 = query.getOrDefault("Action")
  valid_594718 = validateParameter(valid_594718, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594718 != nil:
    section.add "Action", valid_594718
  var valid_594719 = query.getOrDefault("Version")
  valid_594719 = validateParameter(valid_594719, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594719 != nil:
    section.add "Version", valid_594719
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
  var valid_594720 = header.getOrDefault("X-Amz-Date")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-Date", valid_594720
  var valid_594721 = header.getOrDefault("X-Amz-Security-Token")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Security-Token", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Content-Sha256", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-Algorithm")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Algorithm", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Signature")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Signature", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-SignedHeaders", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Credential")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Credential", valid_594726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594727: Call_GetListTagsForResource_594714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_594727.validator(path, query, header, formData, body)
  let scheme = call_594727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594727.url(scheme.get, call_594727.host, call_594727.base,
                         call_594727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594727, url, valid)

proc call*(call_594728: Call_GetListTagsForResource_594714; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594729 = newJObject()
  add(query_594729, "ResourceArn", newJString(ResourceArn))
  add(query_594729, "Action", newJString(Action))
  add(query_594729, "Version", newJString(Version))
  result = call_594728.call(nil, query_594729, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_594714(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_594715, base: "/",
    url: url_GetListTagsForResource_594716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_594763 = ref object of OpenApiRestCall_593437
proc url_PostListTopics_594765(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTopics_594764(path: JsonNode; query: JsonNode;
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
  var valid_594766 = query.getOrDefault("Action")
  valid_594766 = validateParameter(valid_594766, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_594766 != nil:
    section.add "Action", valid_594766
  var valid_594767 = query.getOrDefault("Version")
  valid_594767 = validateParameter(valid_594767, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594767 != nil:
    section.add "Version", valid_594767
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
  var valid_594768 = header.getOrDefault("X-Amz-Date")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "X-Amz-Date", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Security-Token")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Security-Token", valid_594769
  var valid_594770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "X-Amz-Content-Sha256", valid_594770
  var valid_594771 = header.getOrDefault("X-Amz-Algorithm")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-Algorithm", valid_594771
  var valid_594772 = header.getOrDefault("X-Amz-Signature")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-Signature", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-SignedHeaders", valid_594773
  var valid_594774 = header.getOrDefault("X-Amz-Credential")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "X-Amz-Credential", valid_594774
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_594775 = formData.getOrDefault("NextToken")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "NextToken", valid_594775
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594776: Call_PostListTopics_594763; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_594776.validator(path, query, header, formData, body)
  let scheme = call_594776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594776.url(scheme.get, call_594776.host, call_594776.base,
                         call_594776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594776, url, valid)

proc call*(call_594777: Call_PostListTopics_594763; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594778 = newJObject()
  var formData_594779 = newJObject()
  add(formData_594779, "NextToken", newJString(NextToken))
  add(query_594778, "Action", newJString(Action))
  add(query_594778, "Version", newJString(Version))
  result = call_594777.call(nil, query_594778, nil, formData_594779, nil)

var postListTopics* = Call_PostListTopics_594763(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_594764,
    base: "/", url: url_PostListTopics_594765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_594747 = ref object of OpenApiRestCall_593437
proc url_GetListTopics_594749(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTopics_594748(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594750 = query.getOrDefault("NextToken")
  valid_594750 = validateParameter(valid_594750, JString, required = false,
                                 default = nil)
  if valid_594750 != nil:
    section.add "NextToken", valid_594750
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594751 = query.getOrDefault("Action")
  valid_594751 = validateParameter(valid_594751, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_594751 != nil:
    section.add "Action", valid_594751
  var valid_594752 = query.getOrDefault("Version")
  valid_594752 = validateParameter(valid_594752, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594752 != nil:
    section.add "Version", valid_594752
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
  var valid_594753 = header.getOrDefault("X-Amz-Date")
  valid_594753 = validateParameter(valid_594753, JString, required = false,
                                 default = nil)
  if valid_594753 != nil:
    section.add "X-Amz-Date", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Security-Token")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Security-Token", valid_594754
  var valid_594755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Content-Sha256", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-Algorithm")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Algorithm", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-Signature")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Signature", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-SignedHeaders", valid_594758
  var valid_594759 = header.getOrDefault("X-Amz-Credential")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "X-Amz-Credential", valid_594759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594760: Call_GetListTopics_594747; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_594760.validator(path, query, header, formData, body)
  let scheme = call_594760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594760.url(scheme.get, call_594760.host, call_594760.base,
                         call_594760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594760, url, valid)

proc call*(call_594761: Call_GetListTopics_594747; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594762 = newJObject()
  add(query_594762, "NextToken", newJString(NextToken))
  add(query_594762, "Action", newJString(Action))
  add(query_594762, "Version", newJString(Version))
  result = call_594761.call(nil, query_594762, nil, nil, nil)

var getListTopics* = Call_GetListTopics_594747(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_594748,
    base: "/", url: url_GetListTopics_594749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_594796 = ref object of OpenApiRestCall_593437
proc url_PostOptInPhoneNumber_594798(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostOptInPhoneNumber_594797(path: JsonNode; query: JsonNode;
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
  var valid_594799 = query.getOrDefault("Action")
  valid_594799 = validateParameter(valid_594799, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_594799 != nil:
    section.add "Action", valid_594799
  var valid_594800 = query.getOrDefault("Version")
  valid_594800 = validateParameter(valid_594800, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594800 != nil:
    section.add "Version", valid_594800
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
  var valid_594801 = header.getOrDefault("X-Amz-Date")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-Date", valid_594801
  var valid_594802 = header.getOrDefault("X-Amz-Security-Token")
  valid_594802 = validateParameter(valid_594802, JString, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "X-Amz-Security-Token", valid_594802
  var valid_594803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "X-Amz-Content-Sha256", valid_594803
  var valid_594804 = header.getOrDefault("X-Amz-Algorithm")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "X-Amz-Algorithm", valid_594804
  var valid_594805 = header.getOrDefault("X-Amz-Signature")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "X-Amz-Signature", valid_594805
  var valid_594806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-SignedHeaders", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Credential")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Credential", valid_594807
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_594808 = formData.getOrDefault("phoneNumber")
  valid_594808 = validateParameter(valid_594808, JString, required = true,
                                 default = nil)
  if valid_594808 != nil:
    section.add "phoneNumber", valid_594808
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594809: Call_PostOptInPhoneNumber_594796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_594809.validator(path, query, header, formData, body)
  let scheme = call_594809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594809.url(scheme.get, call_594809.host, call_594809.base,
                         call_594809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594809, url, valid)

proc call*(call_594810: Call_PostOptInPhoneNumber_594796; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Version: string (required)
  var query_594811 = newJObject()
  var formData_594812 = newJObject()
  add(query_594811, "Action", newJString(Action))
  add(formData_594812, "phoneNumber", newJString(phoneNumber))
  add(query_594811, "Version", newJString(Version))
  result = call_594810.call(nil, query_594811, nil, formData_594812, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_594796(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_594797, base: "/",
    url: url_PostOptInPhoneNumber_594798, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_594780 = ref object of OpenApiRestCall_593437
proc url_GetOptInPhoneNumber_594782(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOptInPhoneNumber_594781(path: JsonNode; query: JsonNode;
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
  var valid_594783 = query.getOrDefault("phoneNumber")
  valid_594783 = validateParameter(valid_594783, JString, required = true,
                                 default = nil)
  if valid_594783 != nil:
    section.add "phoneNumber", valid_594783
  var valid_594784 = query.getOrDefault("Action")
  valid_594784 = validateParameter(valid_594784, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_594784 != nil:
    section.add "Action", valid_594784
  var valid_594785 = query.getOrDefault("Version")
  valid_594785 = validateParameter(valid_594785, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594785 != nil:
    section.add "Version", valid_594785
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
  var valid_594786 = header.getOrDefault("X-Amz-Date")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "X-Amz-Date", valid_594786
  var valid_594787 = header.getOrDefault("X-Amz-Security-Token")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "X-Amz-Security-Token", valid_594787
  var valid_594788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594788 = validateParameter(valid_594788, JString, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "X-Amz-Content-Sha256", valid_594788
  var valid_594789 = header.getOrDefault("X-Amz-Algorithm")
  valid_594789 = validateParameter(valid_594789, JString, required = false,
                                 default = nil)
  if valid_594789 != nil:
    section.add "X-Amz-Algorithm", valid_594789
  var valid_594790 = header.getOrDefault("X-Amz-Signature")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "X-Amz-Signature", valid_594790
  var valid_594791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-SignedHeaders", valid_594791
  var valid_594792 = header.getOrDefault("X-Amz-Credential")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Credential", valid_594792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594793: Call_GetOptInPhoneNumber_594780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_594793.validator(path, query, header, formData, body)
  let scheme = call_594793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594793.url(scheme.get, call_594793.host, call_594793.base,
                         call_594793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594793, url, valid)

proc call*(call_594794: Call_GetOptInPhoneNumber_594780; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594795 = newJObject()
  add(query_594795, "phoneNumber", newJString(phoneNumber))
  add(query_594795, "Action", newJString(Action))
  add(query_594795, "Version", newJString(Version))
  result = call_594794.call(nil, query_594795, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_594780(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_594781, base: "/",
    url: url_GetOptInPhoneNumber_594782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_594840 = ref object of OpenApiRestCall_593437
proc url_PostPublish_594842(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPublish_594841(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594843 = query.getOrDefault("Action")
  valid_594843 = validateParameter(valid_594843, JString, required = true,
                                 default = newJString("Publish"))
  if valid_594843 != nil:
    section.add "Action", valid_594843
  var valid_594844 = query.getOrDefault("Version")
  valid_594844 = validateParameter(valid_594844, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594844 != nil:
    section.add "Version", valid_594844
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
  var valid_594845 = header.getOrDefault("X-Amz-Date")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Date", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Security-Token")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Security-Token", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-Content-Sha256", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-Algorithm")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Algorithm", valid_594848
  var valid_594849 = header.getOrDefault("X-Amz-Signature")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "X-Amz-Signature", valid_594849
  var valid_594850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594850 = validateParameter(valid_594850, JString, required = false,
                                 default = nil)
  if valid_594850 != nil:
    section.add "X-Amz-SignedHeaders", valid_594850
  var valid_594851 = header.getOrDefault("X-Amz-Credential")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "X-Amz-Credential", valid_594851
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
  var valid_594852 = formData.getOrDefault("TopicArn")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "TopicArn", valid_594852
  var valid_594853 = formData.getOrDefault("Subject")
  valid_594853 = validateParameter(valid_594853, JString, required = false,
                                 default = nil)
  if valid_594853 != nil:
    section.add "Subject", valid_594853
  var valid_594854 = formData.getOrDefault("MessageAttributes.1.key")
  valid_594854 = validateParameter(valid_594854, JString, required = false,
                                 default = nil)
  if valid_594854 != nil:
    section.add "MessageAttributes.1.key", valid_594854
  var valid_594855 = formData.getOrDefault("TargetArn")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "TargetArn", valid_594855
  var valid_594856 = formData.getOrDefault("PhoneNumber")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "PhoneNumber", valid_594856
  var valid_594857 = formData.getOrDefault("MessageAttributes.0.value")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "MessageAttributes.0.value", valid_594857
  var valid_594858 = formData.getOrDefault("MessageAttributes.1.value")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "MessageAttributes.1.value", valid_594858
  var valid_594859 = formData.getOrDefault("MessageAttributes.0.key")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "MessageAttributes.0.key", valid_594859
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_594860 = formData.getOrDefault("Message")
  valid_594860 = validateParameter(valid_594860, JString, required = true,
                                 default = nil)
  if valid_594860 != nil:
    section.add "Message", valid_594860
  var valid_594861 = formData.getOrDefault("MessageStructure")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "MessageStructure", valid_594861
  var valid_594862 = formData.getOrDefault("MessageAttributes.2.key")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "MessageAttributes.2.key", valid_594862
  var valid_594863 = formData.getOrDefault("MessageAttributes.2.value")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "MessageAttributes.2.value", valid_594863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594864: Call_PostPublish_594840; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_594864.validator(path, query, header, formData, body)
  let scheme = call_594864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594864.url(scheme.get, call_594864.host, call_594864.base,
                         call_594864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594864, url, valid)

proc call*(call_594865: Call_PostPublish_594840; Message: string;
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
  var query_594866 = newJObject()
  var formData_594867 = newJObject()
  add(formData_594867, "TopicArn", newJString(TopicArn))
  add(formData_594867, "Subject", newJString(Subject))
  add(formData_594867, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_594867, "TargetArn", newJString(TargetArn))
  add(formData_594867, "PhoneNumber", newJString(PhoneNumber))
  add(formData_594867, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_594867, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_594867, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_594867, "Message", newJString(Message))
  add(query_594866, "Action", newJString(Action))
  add(formData_594867, "MessageStructure", newJString(MessageStructure))
  add(formData_594867, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(query_594866, "Version", newJString(Version))
  add(formData_594867, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  result = call_594865.call(nil, query_594866, nil, formData_594867, nil)

var postPublish* = Call_PostPublish_594840(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_594841,
                                        base: "/", url: url_PostPublish_594842,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_594813 = ref object of OpenApiRestCall_593437
proc url_GetPublish_594815(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPublish_594814(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594816 = query.getOrDefault("MessageAttributes.0.value")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "MessageAttributes.0.value", valid_594816
  var valid_594817 = query.getOrDefault("MessageAttributes.0.key")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "MessageAttributes.0.key", valid_594817
  var valid_594818 = query.getOrDefault("MessageAttributes.1.value")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "MessageAttributes.1.value", valid_594818
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_594819 = query.getOrDefault("Message")
  valid_594819 = validateParameter(valid_594819, JString, required = true,
                                 default = nil)
  if valid_594819 != nil:
    section.add "Message", valid_594819
  var valid_594820 = query.getOrDefault("Subject")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "Subject", valid_594820
  var valid_594821 = query.getOrDefault("Action")
  valid_594821 = validateParameter(valid_594821, JString, required = true,
                                 default = newJString("Publish"))
  if valid_594821 != nil:
    section.add "Action", valid_594821
  var valid_594822 = query.getOrDefault("MessageAttributes.2.value")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "MessageAttributes.2.value", valid_594822
  var valid_594823 = query.getOrDefault("MessageStructure")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "MessageStructure", valid_594823
  var valid_594824 = query.getOrDefault("TopicArn")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "TopicArn", valid_594824
  var valid_594825 = query.getOrDefault("PhoneNumber")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "PhoneNumber", valid_594825
  var valid_594826 = query.getOrDefault("MessageAttributes.1.key")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "MessageAttributes.1.key", valid_594826
  var valid_594827 = query.getOrDefault("MessageAttributes.2.key")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "MessageAttributes.2.key", valid_594827
  var valid_594828 = query.getOrDefault("TargetArn")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "TargetArn", valid_594828
  var valid_594829 = query.getOrDefault("Version")
  valid_594829 = validateParameter(valid_594829, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594829 != nil:
    section.add "Version", valid_594829
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
  var valid_594830 = header.getOrDefault("X-Amz-Date")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Date", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Security-Token")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Security-Token", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-Content-Sha256", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Algorithm")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Algorithm", valid_594833
  var valid_594834 = header.getOrDefault("X-Amz-Signature")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "X-Amz-Signature", valid_594834
  var valid_594835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "X-Amz-SignedHeaders", valid_594835
  var valid_594836 = header.getOrDefault("X-Amz-Credential")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-Credential", valid_594836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594837: Call_GetPublish_594813; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_594837.validator(path, query, header, formData, body)
  let scheme = call_594837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594837.url(scheme.get, call_594837.host, call_594837.base,
                         call_594837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594837, url, valid)

proc call*(call_594838: Call_GetPublish_594813; Message: string;
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
  var query_594839 = newJObject()
  add(query_594839, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_594839, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_594839, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_594839, "Message", newJString(Message))
  add(query_594839, "Subject", newJString(Subject))
  add(query_594839, "Action", newJString(Action))
  add(query_594839, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_594839, "MessageStructure", newJString(MessageStructure))
  add(query_594839, "TopicArn", newJString(TopicArn))
  add(query_594839, "PhoneNumber", newJString(PhoneNumber))
  add(query_594839, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_594839, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_594839, "TargetArn", newJString(TargetArn))
  add(query_594839, "Version", newJString(Version))
  result = call_594838.call(nil, query_594839, nil, nil, nil)

var getPublish* = Call_GetPublish_594813(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_594814,
                                      base: "/", url: url_GetPublish_594815,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_594885 = ref object of OpenApiRestCall_593437
proc url_PostRemovePermission_594887(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemovePermission_594886(path: JsonNode; query: JsonNode;
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
  var valid_594888 = query.getOrDefault("Action")
  valid_594888 = validateParameter(valid_594888, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_594888 != nil:
    section.add "Action", valid_594888
  var valid_594889 = query.getOrDefault("Version")
  valid_594889 = validateParameter(valid_594889, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594889 != nil:
    section.add "Version", valid_594889
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
  var valid_594890 = header.getOrDefault("X-Amz-Date")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "X-Amz-Date", valid_594890
  var valid_594891 = header.getOrDefault("X-Amz-Security-Token")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "X-Amz-Security-Token", valid_594891
  var valid_594892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "X-Amz-Content-Sha256", valid_594892
  var valid_594893 = header.getOrDefault("X-Amz-Algorithm")
  valid_594893 = validateParameter(valid_594893, JString, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "X-Amz-Algorithm", valid_594893
  var valid_594894 = header.getOrDefault("X-Amz-Signature")
  valid_594894 = validateParameter(valid_594894, JString, required = false,
                                 default = nil)
  if valid_594894 != nil:
    section.add "X-Amz-Signature", valid_594894
  var valid_594895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "X-Amz-SignedHeaders", valid_594895
  var valid_594896 = header.getOrDefault("X-Amz-Credential")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-Credential", valid_594896
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_594897 = formData.getOrDefault("TopicArn")
  valid_594897 = validateParameter(valid_594897, JString, required = true,
                                 default = nil)
  if valid_594897 != nil:
    section.add "TopicArn", valid_594897
  var valid_594898 = formData.getOrDefault("Label")
  valid_594898 = validateParameter(valid_594898, JString, required = true,
                                 default = nil)
  if valid_594898 != nil:
    section.add "Label", valid_594898
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594899: Call_PostRemovePermission_594885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_594899.validator(path, query, header, formData, body)
  let scheme = call_594899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594899.url(scheme.get, call_594899.host, call_594899.base,
                         call_594899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594899, url, valid)

proc call*(call_594900: Call_PostRemovePermission_594885; TopicArn: string;
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
  var query_594901 = newJObject()
  var formData_594902 = newJObject()
  add(formData_594902, "TopicArn", newJString(TopicArn))
  add(formData_594902, "Label", newJString(Label))
  add(query_594901, "Action", newJString(Action))
  add(query_594901, "Version", newJString(Version))
  result = call_594900.call(nil, query_594901, nil, formData_594902, nil)

var postRemovePermission* = Call_PostRemovePermission_594885(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_594886, base: "/",
    url: url_PostRemovePermission_594887, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_594868 = ref object of OpenApiRestCall_593437
proc url_GetRemovePermission_594870(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemovePermission_594869(path: JsonNode; query: JsonNode;
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
  var valid_594871 = query.getOrDefault("Action")
  valid_594871 = validateParameter(valid_594871, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_594871 != nil:
    section.add "Action", valid_594871
  var valid_594872 = query.getOrDefault("TopicArn")
  valid_594872 = validateParameter(valid_594872, JString, required = true,
                                 default = nil)
  if valid_594872 != nil:
    section.add "TopicArn", valid_594872
  var valid_594873 = query.getOrDefault("Version")
  valid_594873 = validateParameter(valid_594873, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594873 != nil:
    section.add "Version", valid_594873
  var valid_594874 = query.getOrDefault("Label")
  valid_594874 = validateParameter(valid_594874, JString, required = true,
                                 default = nil)
  if valid_594874 != nil:
    section.add "Label", valid_594874
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
  var valid_594875 = header.getOrDefault("X-Amz-Date")
  valid_594875 = validateParameter(valid_594875, JString, required = false,
                                 default = nil)
  if valid_594875 != nil:
    section.add "X-Amz-Date", valid_594875
  var valid_594876 = header.getOrDefault("X-Amz-Security-Token")
  valid_594876 = validateParameter(valid_594876, JString, required = false,
                                 default = nil)
  if valid_594876 != nil:
    section.add "X-Amz-Security-Token", valid_594876
  var valid_594877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "X-Amz-Content-Sha256", valid_594877
  var valid_594878 = header.getOrDefault("X-Amz-Algorithm")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-Algorithm", valid_594878
  var valid_594879 = header.getOrDefault("X-Amz-Signature")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "X-Amz-Signature", valid_594879
  var valid_594880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594880 = validateParameter(valid_594880, JString, required = false,
                                 default = nil)
  if valid_594880 != nil:
    section.add "X-Amz-SignedHeaders", valid_594880
  var valid_594881 = header.getOrDefault("X-Amz-Credential")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Credential", valid_594881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594882: Call_GetRemovePermission_594868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_594882.validator(path, query, header, formData, body)
  let scheme = call_594882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594882.url(scheme.get, call_594882.host, call_594882.base,
                         call_594882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594882, url, valid)

proc call*(call_594883: Call_GetRemovePermission_594868; TopicArn: string;
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
  var query_594884 = newJObject()
  add(query_594884, "Action", newJString(Action))
  add(query_594884, "TopicArn", newJString(TopicArn))
  add(query_594884, "Version", newJString(Version))
  add(query_594884, "Label", newJString(Label))
  result = call_594883.call(nil, query_594884, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_594868(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_594869, base: "/",
    url: url_GetRemovePermission_594870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_594925 = ref object of OpenApiRestCall_593437
proc url_PostSetEndpointAttributes_594927(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetEndpointAttributes_594926(path: JsonNode; query: JsonNode;
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
  var valid_594928 = query.getOrDefault("Action")
  valid_594928 = validateParameter(valid_594928, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_594928 != nil:
    section.add "Action", valid_594928
  var valid_594929 = query.getOrDefault("Version")
  valid_594929 = validateParameter(valid_594929, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594929 != nil:
    section.add "Version", valid_594929
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
  var valid_594930 = header.getOrDefault("X-Amz-Date")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "X-Amz-Date", valid_594930
  var valid_594931 = header.getOrDefault("X-Amz-Security-Token")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-Security-Token", valid_594931
  var valid_594932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594932 = validateParameter(valid_594932, JString, required = false,
                                 default = nil)
  if valid_594932 != nil:
    section.add "X-Amz-Content-Sha256", valid_594932
  var valid_594933 = header.getOrDefault("X-Amz-Algorithm")
  valid_594933 = validateParameter(valid_594933, JString, required = false,
                                 default = nil)
  if valid_594933 != nil:
    section.add "X-Amz-Algorithm", valid_594933
  var valid_594934 = header.getOrDefault("X-Amz-Signature")
  valid_594934 = validateParameter(valid_594934, JString, required = false,
                                 default = nil)
  if valid_594934 != nil:
    section.add "X-Amz-Signature", valid_594934
  var valid_594935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594935 = validateParameter(valid_594935, JString, required = false,
                                 default = nil)
  if valid_594935 != nil:
    section.add "X-Amz-SignedHeaders", valid_594935
  var valid_594936 = header.getOrDefault("X-Amz-Credential")
  valid_594936 = validateParameter(valid_594936, JString, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "X-Amz-Credential", valid_594936
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
  var valid_594937 = formData.getOrDefault("Attributes.0.value")
  valid_594937 = validateParameter(valid_594937, JString, required = false,
                                 default = nil)
  if valid_594937 != nil:
    section.add "Attributes.0.value", valid_594937
  var valid_594938 = formData.getOrDefault("Attributes.0.key")
  valid_594938 = validateParameter(valid_594938, JString, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "Attributes.0.key", valid_594938
  var valid_594939 = formData.getOrDefault("Attributes.1.key")
  valid_594939 = validateParameter(valid_594939, JString, required = false,
                                 default = nil)
  if valid_594939 != nil:
    section.add "Attributes.1.key", valid_594939
  var valid_594940 = formData.getOrDefault("Attributes.2.value")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "Attributes.2.value", valid_594940
  var valid_594941 = formData.getOrDefault("Attributes.2.key")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "Attributes.2.key", valid_594941
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_594942 = formData.getOrDefault("EndpointArn")
  valid_594942 = validateParameter(valid_594942, JString, required = true,
                                 default = nil)
  if valid_594942 != nil:
    section.add "EndpointArn", valid_594942
  var valid_594943 = formData.getOrDefault("Attributes.1.value")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "Attributes.1.value", valid_594943
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594944: Call_PostSetEndpointAttributes_594925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_594944.validator(path, query, header, formData, body)
  let scheme = call_594944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594944.url(scheme.get, call_594944.host, call_594944.base,
                         call_594944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594944, url, valid)

proc call*(call_594945: Call_PostSetEndpointAttributes_594925; EndpointArn: string;
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
  var query_594946 = newJObject()
  var formData_594947 = newJObject()
  add(formData_594947, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_594947, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_594947, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594946, "Action", newJString(Action))
  add(formData_594947, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_594947, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_594947, "EndpointArn", newJString(EndpointArn))
  add(query_594946, "Version", newJString(Version))
  add(formData_594947, "Attributes.1.value", newJString(Attributes1Value))
  result = call_594945.call(nil, query_594946, nil, formData_594947, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_594925(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_594926, base: "/",
    url: url_PostSetEndpointAttributes_594927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_594903 = ref object of OpenApiRestCall_593437
proc url_GetSetEndpointAttributes_594905(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetEndpointAttributes_594904(path: JsonNode; query: JsonNode;
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
  var valid_594906 = query.getOrDefault("EndpointArn")
  valid_594906 = validateParameter(valid_594906, JString, required = true,
                                 default = nil)
  if valid_594906 != nil:
    section.add "EndpointArn", valid_594906
  var valid_594907 = query.getOrDefault("Attributes.2.key")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "Attributes.2.key", valid_594907
  var valid_594908 = query.getOrDefault("Attributes.1.value")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "Attributes.1.value", valid_594908
  var valid_594909 = query.getOrDefault("Attributes.0.value")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "Attributes.0.value", valid_594909
  var valid_594910 = query.getOrDefault("Action")
  valid_594910 = validateParameter(valid_594910, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_594910 != nil:
    section.add "Action", valid_594910
  var valid_594911 = query.getOrDefault("Attributes.1.key")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "Attributes.1.key", valid_594911
  var valid_594912 = query.getOrDefault("Attributes.2.value")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "Attributes.2.value", valid_594912
  var valid_594913 = query.getOrDefault("Attributes.0.key")
  valid_594913 = validateParameter(valid_594913, JString, required = false,
                                 default = nil)
  if valid_594913 != nil:
    section.add "Attributes.0.key", valid_594913
  var valid_594914 = query.getOrDefault("Version")
  valid_594914 = validateParameter(valid_594914, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594914 != nil:
    section.add "Version", valid_594914
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
  var valid_594915 = header.getOrDefault("X-Amz-Date")
  valid_594915 = validateParameter(valid_594915, JString, required = false,
                                 default = nil)
  if valid_594915 != nil:
    section.add "X-Amz-Date", valid_594915
  var valid_594916 = header.getOrDefault("X-Amz-Security-Token")
  valid_594916 = validateParameter(valid_594916, JString, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "X-Amz-Security-Token", valid_594916
  var valid_594917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "X-Amz-Content-Sha256", valid_594917
  var valid_594918 = header.getOrDefault("X-Amz-Algorithm")
  valid_594918 = validateParameter(valid_594918, JString, required = false,
                                 default = nil)
  if valid_594918 != nil:
    section.add "X-Amz-Algorithm", valid_594918
  var valid_594919 = header.getOrDefault("X-Amz-Signature")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "X-Amz-Signature", valid_594919
  var valid_594920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-SignedHeaders", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Credential")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Credential", valid_594921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594922: Call_GetSetEndpointAttributes_594903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_594922.validator(path, query, header, formData, body)
  let scheme = call_594922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594922.url(scheme.get, call_594922.host, call_594922.base,
                         call_594922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594922, url, valid)

proc call*(call_594923: Call_GetSetEndpointAttributes_594903; EndpointArn: string;
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
  var query_594924 = newJObject()
  add(query_594924, "EndpointArn", newJString(EndpointArn))
  add(query_594924, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594924, "Attributes.1.value", newJString(Attributes1Value))
  add(query_594924, "Attributes.0.value", newJString(Attributes0Value))
  add(query_594924, "Action", newJString(Action))
  add(query_594924, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594924, "Attributes.2.value", newJString(Attributes2Value))
  add(query_594924, "Attributes.0.key", newJString(Attributes0Key))
  add(query_594924, "Version", newJString(Version))
  result = call_594923.call(nil, query_594924, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_594903(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_594904, base: "/",
    url: url_GetSetEndpointAttributes_594905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_594970 = ref object of OpenApiRestCall_593437
proc url_PostSetPlatformApplicationAttributes_594972(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetPlatformApplicationAttributes_594971(path: JsonNode;
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
  var valid_594973 = query.getOrDefault("Action")
  valid_594973 = validateParameter(valid_594973, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_594973 != nil:
    section.add "Action", valid_594973
  var valid_594974 = query.getOrDefault("Version")
  valid_594974 = validateParameter(valid_594974, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594974 != nil:
    section.add "Version", valid_594974
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
  var valid_594975 = header.getOrDefault("X-Amz-Date")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Date", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-Security-Token")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Security-Token", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-Content-Sha256", valid_594977
  var valid_594978 = header.getOrDefault("X-Amz-Algorithm")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "X-Amz-Algorithm", valid_594978
  var valid_594979 = header.getOrDefault("X-Amz-Signature")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "X-Amz-Signature", valid_594979
  var valid_594980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594980 = validateParameter(valid_594980, JString, required = false,
                                 default = nil)
  if valid_594980 != nil:
    section.add "X-Amz-SignedHeaders", valid_594980
  var valid_594981 = header.getOrDefault("X-Amz-Credential")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = nil)
  if valid_594981 != nil:
    section.add "X-Amz-Credential", valid_594981
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
  var valid_594982 = formData.getOrDefault("Attributes.0.value")
  valid_594982 = validateParameter(valid_594982, JString, required = false,
                                 default = nil)
  if valid_594982 != nil:
    section.add "Attributes.0.value", valid_594982
  var valid_594983 = formData.getOrDefault("Attributes.0.key")
  valid_594983 = validateParameter(valid_594983, JString, required = false,
                                 default = nil)
  if valid_594983 != nil:
    section.add "Attributes.0.key", valid_594983
  var valid_594984 = formData.getOrDefault("Attributes.1.key")
  valid_594984 = validateParameter(valid_594984, JString, required = false,
                                 default = nil)
  if valid_594984 != nil:
    section.add "Attributes.1.key", valid_594984
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_594985 = formData.getOrDefault("PlatformApplicationArn")
  valid_594985 = validateParameter(valid_594985, JString, required = true,
                                 default = nil)
  if valid_594985 != nil:
    section.add "PlatformApplicationArn", valid_594985
  var valid_594986 = formData.getOrDefault("Attributes.2.value")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "Attributes.2.value", valid_594986
  var valid_594987 = formData.getOrDefault("Attributes.2.key")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "Attributes.2.key", valid_594987
  var valid_594988 = formData.getOrDefault("Attributes.1.value")
  valid_594988 = validateParameter(valid_594988, JString, required = false,
                                 default = nil)
  if valid_594988 != nil:
    section.add "Attributes.1.value", valid_594988
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594989: Call_PostSetPlatformApplicationAttributes_594970;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_594989.validator(path, query, header, formData, body)
  let scheme = call_594989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594989.url(scheme.get, call_594989.host, call_594989.base,
                         call_594989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594989, url, valid)

proc call*(call_594990: Call_PostSetPlatformApplicationAttributes_594970;
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
  var query_594991 = newJObject()
  var formData_594992 = newJObject()
  add(formData_594992, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_594992, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_594992, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594991, "Action", newJString(Action))
  add(formData_594992, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_594992, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_594992, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594991, "Version", newJString(Version))
  add(formData_594992, "Attributes.1.value", newJString(Attributes1Value))
  result = call_594990.call(nil, query_594991, nil, formData_594992, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_594970(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_594971, base: "/",
    url: url_PostSetPlatformApplicationAttributes_594972,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_594948 = ref object of OpenApiRestCall_593437
proc url_GetSetPlatformApplicationAttributes_594950(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetPlatformApplicationAttributes_594949(path: JsonNode;
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
  var valid_594951 = query.getOrDefault("Attributes.2.key")
  valid_594951 = validateParameter(valid_594951, JString, required = false,
                                 default = nil)
  if valid_594951 != nil:
    section.add "Attributes.2.key", valid_594951
  var valid_594952 = query.getOrDefault("Attributes.1.value")
  valid_594952 = validateParameter(valid_594952, JString, required = false,
                                 default = nil)
  if valid_594952 != nil:
    section.add "Attributes.1.value", valid_594952
  var valid_594953 = query.getOrDefault("Attributes.0.value")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "Attributes.0.value", valid_594953
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594954 = query.getOrDefault("Action")
  valid_594954 = validateParameter(valid_594954, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_594954 != nil:
    section.add "Action", valid_594954
  var valid_594955 = query.getOrDefault("Attributes.1.key")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "Attributes.1.key", valid_594955
  var valid_594956 = query.getOrDefault("Attributes.2.value")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "Attributes.2.value", valid_594956
  var valid_594957 = query.getOrDefault("Attributes.0.key")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "Attributes.0.key", valid_594957
  var valid_594958 = query.getOrDefault("Version")
  valid_594958 = validateParameter(valid_594958, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594958 != nil:
    section.add "Version", valid_594958
  var valid_594959 = query.getOrDefault("PlatformApplicationArn")
  valid_594959 = validateParameter(valid_594959, JString, required = true,
                                 default = nil)
  if valid_594959 != nil:
    section.add "PlatformApplicationArn", valid_594959
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
  var valid_594960 = header.getOrDefault("X-Amz-Date")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Date", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-Security-Token")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-Security-Token", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-Content-Sha256", valid_594962
  var valid_594963 = header.getOrDefault("X-Amz-Algorithm")
  valid_594963 = validateParameter(valid_594963, JString, required = false,
                                 default = nil)
  if valid_594963 != nil:
    section.add "X-Amz-Algorithm", valid_594963
  var valid_594964 = header.getOrDefault("X-Amz-Signature")
  valid_594964 = validateParameter(valid_594964, JString, required = false,
                                 default = nil)
  if valid_594964 != nil:
    section.add "X-Amz-Signature", valid_594964
  var valid_594965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594965 = validateParameter(valid_594965, JString, required = false,
                                 default = nil)
  if valid_594965 != nil:
    section.add "X-Amz-SignedHeaders", valid_594965
  var valid_594966 = header.getOrDefault("X-Amz-Credential")
  valid_594966 = validateParameter(valid_594966, JString, required = false,
                                 default = nil)
  if valid_594966 != nil:
    section.add "X-Amz-Credential", valid_594966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594967: Call_GetSetPlatformApplicationAttributes_594948;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_594967.validator(path, query, header, formData, body)
  let scheme = call_594967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594967.url(scheme.get, call_594967.host, call_594967.base,
                         call_594967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594967, url, valid)

proc call*(call_594968: Call_GetSetPlatformApplicationAttributes_594948;
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
  var query_594969 = newJObject()
  add(query_594969, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594969, "Attributes.1.value", newJString(Attributes1Value))
  add(query_594969, "Attributes.0.value", newJString(Attributes0Value))
  add(query_594969, "Action", newJString(Action))
  add(query_594969, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594969, "Attributes.2.value", newJString(Attributes2Value))
  add(query_594969, "Attributes.0.key", newJString(Attributes0Key))
  add(query_594969, "Version", newJString(Version))
  add(query_594969, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_594968.call(nil, query_594969, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_594948(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_594949, base: "/",
    url: url_GetSetPlatformApplicationAttributes_594950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_595014 = ref object of OpenApiRestCall_593437
proc url_PostSetSMSAttributes_595016(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSMSAttributes_595015(path: JsonNode; query: JsonNode;
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
  var valid_595017 = query.getOrDefault("Action")
  valid_595017 = validateParameter(valid_595017, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_595017 != nil:
    section.add "Action", valid_595017
  var valid_595018 = query.getOrDefault("Version")
  valid_595018 = validateParameter(valid_595018, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595018 != nil:
    section.add "Version", valid_595018
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
  var valid_595019 = header.getOrDefault("X-Amz-Date")
  valid_595019 = validateParameter(valid_595019, JString, required = false,
                                 default = nil)
  if valid_595019 != nil:
    section.add "X-Amz-Date", valid_595019
  var valid_595020 = header.getOrDefault("X-Amz-Security-Token")
  valid_595020 = validateParameter(valid_595020, JString, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "X-Amz-Security-Token", valid_595020
  var valid_595021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-Content-Sha256", valid_595021
  var valid_595022 = header.getOrDefault("X-Amz-Algorithm")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-Algorithm", valid_595022
  var valid_595023 = header.getOrDefault("X-Amz-Signature")
  valid_595023 = validateParameter(valid_595023, JString, required = false,
                                 default = nil)
  if valid_595023 != nil:
    section.add "X-Amz-Signature", valid_595023
  var valid_595024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "X-Amz-SignedHeaders", valid_595024
  var valid_595025 = header.getOrDefault("X-Amz-Credential")
  valid_595025 = validateParameter(valid_595025, JString, required = false,
                                 default = nil)
  if valid_595025 != nil:
    section.add "X-Amz-Credential", valid_595025
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.2.value: JString
  ##   attributes.2.key: JString
  ##   attributes.1.value: JString
  ##   attributes.1.key: JString
  ##   attributes.0.key: JString
  ##   attributes.0.value: JString
  section = newJObject()
  var valid_595026 = formData.getOrDefault("attributes.2.value")
  valid_595026 = validateParameter(valid_595026, JString, required = false,
                                 default = nil)
  if valid_595026 != nil:
    section.add "attributes.2.value", valid_595026
  var valid_595027 = formData.getOrDefault("attributes.2.key")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "attributes.2.key", valid_595027
  var valid_595028 = formData.getOrDefault("attributes.1.value")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "attributes.1.value", valid_595028
  var valid_595029 = formData.getOrDefault("attributes.1.key")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "attributes.1.key", valid_595029
  var valid_595030 = formData.getOrDefault("attributes.0.key")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "attributes.0.key", valid_595030
  var valid_595031 = formData.getOrDefault("attributes.0.value")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "attributes.0.value", valid_595031
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595032: Call_PostSetSMSAttributes_595014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_595032.validator(path, query, header, formData, body)
  let scheme = call_595032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595032.url(scheme.get, call_595032.host, call_595032.base,
                         call_595032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595032, url, valid)

proc call*(call_595033: Call_PostSetSMSAttributes_595014;
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
  var query_595034 = newJObject()
  var formData_595035 = newJObject()
  add(formData_595035, "attributes.2.value", newJString(attributes2Value))
  add(formData_595035, "attributes.2.key", newJString(attributes2Key))
  add(query_595034, "Action", newJString(Action))
  add(formData_595035, "attributes.1.value", newJString(attributes1Value))
  add(formData_595035, "attributes.1.key", newJString(attributes1Key))
  add(formData_595035, "attributes.0.key", newJString(attributes0Key))
  add(query_595034, "Version", newJString(Version))
  add(formData_595035, "attributes.0.value", newJString(attributes0Value))
  result = call_595033.call(nil, query_595034, nil, formData_595035, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_595014(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_595015, base: "/",
    url: url_PostSetSMSAttributes_595016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_594993 = ref object of OpenApiRestCall_593437
proc url_GetSetSMSAttributes_594995(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSMSAttributes_594994(path: JsonNode; query: JsonNode;
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
  var valid_594996 = query.getOrDefault("attributes.2.key")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "attributes.2.key", valid_594996
  var valid_594997 = query.getOrDefault("attributes.1.key")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "attributes.1.key", valid_594997
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594998 = query.getOrDefault("Action")
  valid_594998 = validateParameter(valid_594998, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_594998 != nil:
    section.add "Action", valid_594998
  var valid_594999 = query.getOrDefault("attributes.1.value")
  valid_594999 = validateParameter(valid_594999, JString, required = false,
                                 default = nil)
  if valid_594999 != nil:
    section.add "attributes.1.value", valid_594999
  var valid_595000 = query.getOrDefault("attributes.0.value")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "attributes.0.value", valid_595000
  var valid_595001 = query.getOrDefault("attributes.2.value")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "attributes.2.value", valid_595001
  var valid_595002 = query.getOrDefault("attributes.0.key")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "attributes.0.key", valid_595002
  var valid_595003 = query.getOrDefault("Version")
  valid_595003 = validateParameter(valid_595003, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595003 != nil:
    section.add "Version", valid_595003
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
  var valid_595004 = header.getOrDefault("X-Amz-Date")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "X-Amz-Date", valid_595004
  var valid_595005 = header.getOrDefault("X-Amz-Security-Token")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "X-Amz-Security-Token", valid_595005
  var valid_595006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-Content-Sha256", valid_595006
  var valid_595007 = header.getOrDefault("X-Amz-Algorithm")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Algorithm", valid_595007
  var valid_595008 = header.getOrDefault("X-Amz-Signature")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "X-Amz-Signature", valid_595008
  var valid_595009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-SignedHeaders", valid_595009
  var valid_595010 = header.getOrDefault("X-Amz-Credential")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "X-Amz-Credential", valid_595010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595011: Call_GetSetSMSAttributes_594993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_595011.validator(path, query, header, formData, body)
  let scheme = call_595011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595011.url(scheme.get, call_595011.host, call_595011.base,
                         call_595011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595011, url, valid)

proc call*(call_595012: Call_GetSetSMSAttributes_594993;
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
  var query_595013 = newJObject()
  add(query_595013, "attributes.2.key", newJString(attributes2Key))
  add(query_595013, "attributes.1.key", newJString(attributes1Key))
  add(query_595013, "Action", newJString(Action))
  add(query_595013, "attributes.1.value", newJString(attributes1Value))
  add(query_595013, "attributes.0.value", newJString(attributes0Value))
  add(query_595013, "attributes.2.value", newJString(attributes2Value))
  add(query_595013, "attributes.0.key", newJString(attributes0Key))
  add(query_595013, "Version", newJString(Version))
  result = call_595012.call(nil, query_595013, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_594993(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_594994, base: "/",
    url: url_GetSetSMSAttributes_594995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_595054 = ref object of OpenApiRestCall_593437
proc url_PostSetSubscriptionAttributes_595056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSubscriptionAttributes_595055(path: JsonNode; query: JsonNode;
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
  var valid_595057 = query.getOrDefault("Action")
  valid_595057 = validateParameter(valid_595057, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_595057 != nil:
    section.add "Action", valid_595057
  var valid_595058 = query.getOrDefault("Version")
  valid_595058 = validateParameter(valid_595058, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595058 != nil:
    section.add "Version", valid_595058
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
  var valid_595059 = header.getOrDefault("X-Amz-Date")
  valid_595059 = validateParameter(valid_595059, JString, required = false,
                                 default = nil)
  if valid_595059 != nil:
    section.add "X-Amz-Date", valid_595059
  var valid_595060 = header.getOrDefault("X-Amz-Security-Token")
  valid_595060 = validateParameter(valid_595060, JString, required = false,
                                 default = nil)
  if valid_595060 != nil:
    section.add "X-Amz-Security-Token", valid_595060
  var valid_595061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595061 = validateParameter(valid_595061, JString, required = false,
                                 default = nil)
  if valid_595061 != nil:
    section.add "X-Amz-Content-Sha256", valid_595061
  var valid_595062 = header.getOrDefault("X-Amz-Algorithm")
  valid_595062 = validateParameter(valid_595062, JString, required = false,
                                 default = nil)
  if valid_595062 != nil:
    section.add "X-Amz-Algorithm", valid_595062
  var valid_595063 = header.getOrDefault("X-Amz-Signature")
  valid_595063 = validateParameter(valid_595063, JString, required = false,
                                 default = nil)
  if valid_595063 != nil:
    section.add "X-Amz-Signature", valid_595063
  var valid_595064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "X-Amz-SignedHeaders", valid_595064
  var valid_595065 = header.getOrDefault("X-Amz-Credential")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "X-Amz-Credential", valid_595065
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
  var valid_595066 = formData.getOrDefault("AttributeName")
  valid_595066 = validateParameter(valid_595066, JString, required = true,
                                 default = nil)
  if valid_595066 != nil:
    section.add "AttributeName", valid_595066
  var valid_595067 = formData.getOrDefault("AttributeValue")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "AttributeValue", valid_595067
  var valid_595068 = formData.getOrDefault("SubscriptionArn")
  valid_595068 = validateParameter(valid_595068, JString, required = true,
                                 default = nil)
  if valid_595068 != nil:
    section.add "SubscriptionArn", valid_595068
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595069: Call_PostSetSubscriptionAttributes_595054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_595069.validator(path, query, header, formData, body)
  let scheme = call_595069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595069.url(scheme.get, call_595069.host, call_595069.base,
                         call_595069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595069, url, valid)

proc call*(call_595070: Call_PostSetSubscriptionAttributes_595054;
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
  var query_595071 = newJObject()
  var formData_595072 = newJObject()
  add(formData_595072, "AttributeName", newJString(AttributeName))
  add(formData_595072, "AttributeValue", newJString(AttributeValue))
  add(query_595071, "Action", newJString(Action))
  add(formData_595072, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_595071, "Version", newJString(Version))
  result = call_595070.call(nil, query_595071, nil, formData_595072, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_595054(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_595055, base: "/",
    url: url_PostSetSubscriptionAttributes_595056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_595036 = ref object of OpenApiRestCall_593437
proc url_GetSetSubscriptionAttributes_595038(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSubscriptionAttributes_595037(path: JsonNode; query: JsonNode;
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
  var valid_595039 = query.getOrDefault("SubscriptionArn")
  valid_595039 = validateParameter(valid_595039, JString, required = true,
                                 default = nil)
  if valid_595039 != nil:
    section.add "SubscriptionArn", valid_595039
  var valid_595040 = query.getOrDefault("AttributeName")
  valid_595040 = validateParameter(valid_595040, JString, required = true,
                                 default = nil)
  if valid_595040 != nil:
    section.add "AttributeName", valid_595040
  var valid_595041 = query.getOrDefault("Action")
  valid_595041 = validateParameter(valid_595041, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_595041 != nil:
    section.add "Action", valid_595041
  var valid_595042 = query.getOrDefault("AttributeValue")
  valid_595042 = validateParameter(valid_595042, JString, required = false,
                                 default = nil)
  if valid_595042 != nil:
    section.add "AttributeValue", valid_595042
  var valid_595043 = query.getOrDefault("Version")
  valid_595043 = validateParameter(valid_595043, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595043 != nil:
    section.add "Version", valid_595043
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
  var valid_595044 = header.getOrDefault("X-Amz-Date")
  valid_595044 = validateParameter(valid_595044, JString, required = false,
                                 default = nil)
  if valid_595044 != nil:
    section.add "X-Amz-Date", valid_595044
  var valid_595045 = header.getOrDefault("X-Amz-Security-Token")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "X-Amz-Security-Token", valid_595045
  var valid_595046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Content-Sha256", valid_595046
  var valid_595047 = header.getOrDefault("X-Amz-Algorithm")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Algorithm", valid_595047
  var valid_595048 = header.getOrDefault("X-Amz-Signature")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-Signature", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-SignedHeaders", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Credential")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Credential", valid_595050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595051: Call_GetSetSubscriptionAttributes_595036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_595051.validator(path, query, header, formData, body)
  let scheme = call_595051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595051.url(scheme.get, call_595051.host, call_595051.base,
                         call_595051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595051, url, valid)

proc call*(call_595052: Call_GetSetSubscriptionAttributes_595036;
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
  var query_595053 = newJObject()
  add(query_595053, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_595053, "AttributeName", newJString(AttributeName))
  add(query_595053, "Action", newJString(Action))
  add(query_595053, "AttributeValue", newJString(AttributeValue))
  add(query_595053, "Version", newJString(Version))
  result = call_595052.call(nil, query_595053, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_595036(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_595037, base: "/",
    url: url_GetSetSubscriptionAttributes_595038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_595091 = ref object of OpenApiRestCall_593437
proc url_PostSetTopicAttributes_595093(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetTopicAttributes_595092(path: JsonNode; query: JsonNode;
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
  var valid_595094 = query.getOrDefault("Action")
  valid_595094 = validateParameter(valid_595094, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_595094 != nil:
    section.add "Action", valid_595094
  var valid_595095 = query.getOrDefault("Version")
  valid_595095 = validateParameter(valid_595095, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595095 != nil:
    section.add "Version", valid_595095
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
  var valid_595096 = header.getOrDefault("X-Amz-Date")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "X-Amz-Date", valid_595096
  var valid_595097 = header.getOrDefault("X-Amz-Security-Token")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "X-Amz-Security-Token", valid_595097
  var valid_595098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595098 = validateParameter(valid_595098, JString, required = false,
                                 default = nil)
  if valid_595098 != nil:
    section.add "X-Amz-Content-Sha256", valid_595098
  var valid_595099 = header.getOrDefault("X-Amz-Algorithm")
  valid_595099 = validateParameter(valid_595099, JString, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "X-Amz-Algorithm", valid_595099
  var valid_595100 = header.getOrDefault("X-Amz-Signature")
  valid_595100 = validateParameter(valid_595100, JString, required = false,
                                 default = nil)
  if valid_595100 != nil:
    section.add "X-Amz-Signature", valid_595100
  var valid_595101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "X-Amz-SignedHeaders", valid_595101
  var valid_595102 = header.getOrDefault("X-Amz-Credential")
  valid_595102 = validateParameter(valid_595102, JString, required = false,
                                 default = nil)
  if valid_595102 != nil:
    section.add "X-Amz-Credential", valid_595102
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
  var valid_595103 = formData.getOrDefault("TopicArn")
  valid_595103 = validateParameter(valid_595103, JString, required = true,
                                 default = nil)
  if valid_595103 != nil:
    section.add "TopicArn", valid_595103
  var valid_595104 = formData.getOrDefault("AttributeName")
  valid_595104 = validateParameter(valid_595104, JString, required = true,
                                 default = nil)
  if valid_595104 != nil:
    section.add "AttributeName", valid_595104
  var valid_595105 = formData.getOrDefault("AttributeValue")
  valid_595105 = validateParameter(valid_595105, JString, required = false,
                                 default = nil)
  if valid_595105 != nil:
    section.add "AttributeValue", valid_595105
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595106: Call_PostSetTopicAttributes_595091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_595106.validator(path, query, header, formData, body)
  let scheme = call_595106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595106.url(scheme.get, call_595106.host, call_595106.base,
                         call_595106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595106, url, valid)

proc call*(call_595107: Call_PostSetTopicAttributes_595091; TopicArn: string;
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
  var query_595108 = newJObject()
  var formData_595109 = newJObject()
  add(formData_595109, "TopicArn", newJString(TopicArn))
  add(formData_595109, "AttributeName", newJString(AttributeName))
  add(formData_595109, "AttributeValue", newJString(AttributeValue))
  add(query_595108, "Action", newJString(Action))
  add(query_595108, "Version", newJString(Version))
  result = call_595107.call(nil, query_595108, nil, formData_595109, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_595091(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_595092, base: "/",
    url: url_PostSetTopicAttributes_595093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_595073 = ref object of OpenApiRestCall_593437
proc url_GetSetTopicAttributes_595075(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetTopicAttributes_595074(path: JsonNode; query: JsonNode;
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
  var valid_595076 = query.getOrDefault("AttributeName")
  valid_595076 = validateParameter(valid_595076, JString, required = true,
                                 default = nil)
  if valid_595076 != nil:
    section.add "AttributeName", valid_595076
  var valid_595077 = query.getOrDefault("Action")
  valid_595077 = validateParameter(valid_595077, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_595077 != nil:
    section.add "Action", valid_595077
  var valid_595078 = query.getOrDefault("AttributeValue")
  valid_595078 = validateParameter(valid_595078, JString, required = false,
                                 default = nil)
  if valid_595078 != nil:
    section.add "AttributeValue", valid_595078
  var valid_595079 = query.getOrDefault("TopicArn")
  valid_595079 = validateParameter(valid_595079, JString, required = true,
                                 default = nil)
  if valid_595079 != nil:
    section.add "TopicArn", valid_595079
  var valid_595080 = query.getOrDefault("Version")
  valid_595080 = validateParameter(valid_595080, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595080 != nil:
    section.add "Version", valid_595080
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
  var valid_595081 = header.getOrDefault("X-Amz-Date")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-Date", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Security-Token")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Security-Token", valid_595082
  var valid_595083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595083 = validateParameter(valid_595083, JString, required = false,
                                 default = nil)
  if valid_595083 != nil:
    section.add "X-Amz-Content-Sha256", valid_595083
  var valid_595084 = header.getOrDefault("X-Amz-Algorithm")
  valid_595084 = validateParameter(valid_595084, JString, required = false,
                                 default = nil)
  if valid_595084 != nil:
    section.add "X-Amz-Algorithm", valid_595084
  var valid_595085 = header.getOrDefault("X-Amz-Signature")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "X-Amz-Signature", valid_595085
  var valid_595086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "X-Amz-SignedHeaders", valid_595086
  var valid_595087 = header.getOrDefault("X-Amz-Credential")
  valid_595087 = validateParameter(valid_595087, JString, required = false,
                                 default = nil)
  if valid_595087 != nil:
    section.add "X-Amz-Credential", valid_595087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595088: Call_GetSetTopicAttributes_595073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_595088.validator(path, query, header, formData, body)
  let scheme = call_595088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595088.url(scheme.get, call_595088.host, call_595088.base,
                         call_595088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595088, url, valid)

proc call*(call_595089: Call_GetSetTopicAttributes_595073; AttributeName: string;
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
  var query_595090 = newJObject()
  add(query_595090, "AttributeName", newJString(AttributeName))
  add(query_595090, "Action", newJString(Action))
  add(query_595090, "AttributeValue", newJString(AttributeValue))
  add(query_595090, "TopicArn", newJString(TopicArn))
  add(query_595090, "Version", newJString(Version))
  result = call_595089.call(nil, query_595090, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_595073(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_595074, base: "/",
    url: url_GetSetTopicAttributes_595075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_595135 = ref object of OpenApiRestCall_593437
proc url_PostSubscribe_595137(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSubscribe_595136(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595138 = query.getOrDefault("Action")
  valid_595138 = validateParameter(valid_595138, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_595138 != nil:
    section.add "Action", valid_595138
  var valid_595139 = query.getOrDefault("Version")
  valid_595139 = validateParameter(valid_595139, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595139 != nil:
    section.add "Version", valid_595139
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
  var valid_595140 = header.getOrDefault("X-Amz-Date")
  valid_595140 = validateParameter(valid_595140, JString, required = false,
                                 default = nil)
  if valid_595140 != nil:
    section.add "X-Amz-Date", valid_595140
  var valid_595141 = header.getOrDefault("X-Amz-Security-Token")
  valid_595141 = validateParameter(valid_595141, JString, required = false,
                                 default = nil)
  if valid_595141 != nil:
    section.add "X-Amz-Security-Token", valid_595141
  var valid_595142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "X-Amz-Content-Sha256", valid_595142
  var valid_595143 = header.getOrDefault("X-Amz-Algorithm")
  valid_595143 = validateParameter(valid_595143, JString, required = false,
                                 default = nil)
  if valid_595143 != nil:
    section.add "X-Amz-Algorithm", valid_595143
  var valid_595144 = header.getOrDefault("X-Amz-Signature")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "X-Amz-Signature", valid_595144
  var valid_595145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "X-Amz-SignedHeaders", valid_595145
  var valid_595146 = header.getOrDefault("X-Amz-Credential")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "X-Amz-Credential", valid_595146
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
  var valid_595147 = formData.getOrDefault("Endpoint")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "Endpoint", valid_595147
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_595148 = formData.getOrDefault("TopicArn")
  valid_595148 = validateParameter(valid_595148, JString, required = true,
                                 default = nil)
  if valid_595148 != nil:
    section.add "TopicArn", valid_595148
  var valid_595149 = formData.getOrDefault("Attributes.0.value")
  valid_595149 = validateParameter(valid_595149, JString, required = false,
                                 default = nil)
  if valid_595149 != nil:
    section.add "Attributes.0.value", valid_595149
  var valid_595150 = formData.getOrDefault("Protocol")
  valid_595150 = validateParameter(valid_595150, JString, required = true,
                                 default = nil)
  if valid_595150 != nil:
    section.add "Protocol", valid_595150
  var valid_595151 = formData.getOrDefault("Attributes.0.key")
  valid_595151 = validateParameter(valid_595151, JString, required = false,
                                 default = nil)
  if valid_595151 != nil:
    section.add "Attributes.0.key", valid_595151
  var valid_595152 = formData.getOrDefault("Attributes.1.key")
  valid_595152 = validateParameter(valid_595152, JString, required = false,
                                 default = nil)
  if valid_595152 != nil:
    section.add "Attributes.1.key", valid_595152
  var valid_595153 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_595153 = validateParameter(valid_595153, JBool, required = false, default = nil)
  if valid_595153 != nil:
    section.add "ReturnSubscriptionArn", valid_595153
  var valid_595154 = formData.getOrDefault("Attributes.2.value")
  valid_595154 = validateParameter(valid_595154, JString, required = false,
                                 default = nil)
  if valid_595154 != nil:
    section.add "Attributes.2.value", valid_595154
  var valid_595155 = formData.getOrDefault("Attributes.2.key")
  valid_595155 = validateParameter(valid_595155, JString, required = false,
                                 default = nil)
  if valid_595155 != nil:
    section.add "Attributes.2.key", valid_595155
  var valid_595156 = formData.getOrDefault("Attributes.1.value")
  valid_595156 = validateParameter(valid_595156, JString, required = false,
                                 default = nil)
  if valid_595156 != nil:
    section.add "Attributes.1.value", valid_595156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595157: Call_PostSubscribe_595135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_595157.validator(path, query, header, formData, body)
  let scheme = call_595157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595157.url(scheme.get, call_595157.host, call_595157.base,
                         call_595157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595157, url, valid)

proc call*(call_595158: Call_PostSubscribe_595135; TopicArn: string;
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
  var query_595159 = newJObject()
  var formData_595160 = newJObject()
  add(formData_595160, "Endpoint", newJString(Endpoint))
  add(formData_595160, "TopicArn", newJString(TopicArn))
  add(formData_595160, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_595160, "Protocol", newJString(Protocol))
  add(formData_595160, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_595160, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_595160, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_595159, "Action", newJString(Action))
  add(formData_595160, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_595160, "Attributes.2.key", newJString(Attributes2Key))
  add(query_595159, "Version", newJString(Version))
  add(formData_595160, "Attributes.1.value", newJString(Attributes1Value))
  result = call_595158.call(nil, query_595159, nil, formData_595160, nil)

var postSubscribe* = Call_PostSubscribe_595135(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_595136,
    base: "/", url: url_PostSubscribe_595137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_595110 = ref object of OpenApiRestCall_593437
proc url_GetSubscribe_595112(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSubscribe_595111(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595113 = query.getOrDefault("Attributes.2.key")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "Attributes.2.key", valid_595113
  var valid_595114 = query.getOrDefault("Endpoint")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "Endpoint", valid_595114
  assert query != nil,
        "query argument is necessary due to required `Protocol` field"
  var valid_595115 = query.getOrDefault("Protocol")
  valid_595115 = validateParameter(valid_595115, JString, required = true,
                                 default = nil)
  if valid_595115 != nil:
    section.add "Protocol", valid_595115
  var valid_595116 = query.getOrDefault("Attributes.1.value")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "Attributes.1.value", valid_595116
  var valid_595117 = query.getOrDefault("Attributes.0.value")
  valid_595117 = validateParameter(valid_595117, JString, required = false,
                                 default = nil)
  if valid_595117 != nil:
    section.add "Attributes.0.value", valid_595117
  var valid_595118 = query.getOrDefault("Action")
  valid_595118 = validateParameter(valid_595118, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_595118 != nil:
    section.add "Action", valid_595118
  var valid_595119 = query.getOrDefault("ReturnSubscriptionArn")
  valid_595119 = validateParameter(valid_595119, JBool, required = false, default = nil)
  if valid_595119 != nil:
    section.add "ReturnSubscriptionArn", valid_595119
  var valid_595120 = query.getOrDefault("Attributes.1.key")
  valid_595120 = validateParameter(valid_595120, JString, required = false,
                                 default = nil)
  if valid_595120 != nil:
    section.add "Attributes.1.key", valid_595120
  var valid_595121 = query.getOrDefault("TopicArn")
  valid_595121 = validateParameter(valid_595121, JString, required = true,
                                 default = nil)
  if valid_595121 != nil:
    section.add "TopicArn", valid_595121
  var valid_595122 = query.getOrDefault("Attributes.2.value")
  valid_595122 = validateParameter(valid_595122, JString, required = false,
                                 default = nil)
  if valid_595122 != nil:
    section.add "Attributes.2.value", valid_595122
  var valid_595123 = query.getOrDefault("Attributes.0.key")
  valid_595123 = validateParameter(valid_595123, JString, required = false,
                                 default = nil)
  if valid_595123 != nil:
    section.add "Attributes.0.key", valid_595123
  var valid_595124 = query.getOrDefault("Version")
  valid_595124 = validateParameter(valid_595124, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595124 != nil:
    section.add "Version", valid_595124
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
  var valid_595125 = header.getOrDefault("X-Amz-Date")
  valid_595125 = validateParameter(valid_595125, JString, required = false,
                                 default = nil)
  if valid_595125 != nil:
    section.add "X-Amz-Date", valid_595125
  var valid_595126 = header.getOrDefault("X-Amz-Security-Token")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "X-Amz-Security-Token", valid_595126
  var valid_595127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-Content-Sha256", valid_595127
  var valid_595128 = header.getOrDefault("X-Amz-Algorithm")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "X-Amz-Algorithm", valid_595128
  var valid_595129 = header.getOrDefault("X-Amz-Signature")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "X-Amz-Signature", valid_595129
  var valid_595130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-SignedHeaders", valid_595130
  var valid_595131 = header.getOrDefault("X-Amz-Credential")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "X-Amz-Credential", valid_595131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595132: Call_GetSubscribe_595110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_595132.validator(path, query, header, formData, body)
  let scheme = call_595132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595132.url(scheme.get, call_595132.host, call_595132.base,
                         call_595132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595132, url, valid)

proc call*(call_595133: Call_GetSubscribe_595110; Protocol: string; TopicArn: string;
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
  var query_595134 = newJObject()
  add(query_595134, "Attributes.2.key", newJString(Attributes2Key))
  add(query_595134, "Endpoint", newJString(Endpoint))
  add(query_595134, "Protocol", newJString(Protocol))
  add(query_595134, "Attributes.1.value", newJString(Attributes1Value))
  add(query_595134, "Attributes.0.value", newJString(Attributes0Value))
  add(query_595134, "Action", newJString(Action))
  add(query_595134, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_595134, "Attributes.1.key", newJString(Attributes1Key))
  add(query_595134, "TopicArn", newJString(TopicArn))
  add(query_595134, "Attributes.2.value", newJString(Attributes2Value))
  add(query_595134, "Attributes.0.key", newJString(Attributes0Key))
  add(query_595134, "Version", newJString(Version))
  result = call_595133.call(nil, query_595134, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_595110(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_595111, base: "/",
    url: url_GetSubscribe_595112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_595178 = ref object of OpenApiRestCall_593437
proc url_PostTagResource_595180(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTagResource_595179(path: JsonNode; query: JsonNode;
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
  var valid_595181 = query.getOrDefault("Action")
  valid_595181 = validateParameter(valid_595181, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_595181 != nil:
    section.add "Action", valid_595181
  var valid_595182 = query.getOrDefault("Version")
  valid_595182 = validateParameter(valid_595182, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595182 != nil:
    section.add "Version", valid_595182
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
  var valid_595183 = header.getOrDefault("X-Amz-Date")
  valid_595183 = validateParameter(valid_595183, JString, required = false,
                                 default = nil)
  if valid_595183 != nil:
    section.add "X-Amz-Date", valid_595183
  var valid_595184 = header.getOrDefault("X-Amz-Security-Token")
  valid_595184 = validateParameter(valid_595184, JString, required = false,
                                 default = nil)
  if valid_595184 != nil:
    section.add "X-Amz-Security-Token", valid_595184
  var valid_595185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595185 = validateParameter(valid_595185, JString, required = false,
                                 default = nil)
  if valid_595185 != nil:
    section.add "X-Amz-Content-Sha256", valid_595185
  var valid_595186 = header.getOrDefault("X-Amz-Algorithm")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "X-Amz-Algorithm", valid_595186
  var valid_595187 = header.getOrDefault("X-Amz-Signature")
  valid_595187 = validateParameter(valid_595187, JString, required = false,
                                 default = nil)
  if valid_595187 != nil:
    section.add "X-Amz-Signature", valid_595187
  var valid_595188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595188 = validateParameter(valid_595188, JString, required = false,
                                 default = nil)
  if valid_595188 != nil:
    section.add "X-Amz-SignedHeaders", valid_595188
  var valid_595189 = header.getOrDefault("X-Amz-Credential")
  valid_595189 = validateParameter(valid_595189, JString, required = false,
                                 default = nil)
  if valid_595189 != nil:
    section.add "X-Amz-Credential", valid_595189
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_595190 = formData.getOrDefault("Tags")
  valid_595190 = validateParameter(valid_595190, JArray, required = true, default = nil)
  if valid_595190 != nil:
    section.add "Tags", valid_595190
  var valid_595191 = formData.getOrDefault("ResourceArn")
  valid_595191 = validateParameter(valid_595191, JString, required = true,
                                 default = nil)
  if valid_595191 != nil:
    section.add "ResourceArn", valid_595191
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595192: Call_PostTagResource_595178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_595192.validator(path, query, header, formData, body)
  let scheme = call_595192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595192.url(scheme.get, call_595192.host, call_595192.base,
                         call_595192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595192, url, valid)

proc call*(call_595193: Call_PostTagResource_595178; Tags: JsonNode;
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
  var query_595194 = newJObject()
  var formData_595195 = newJObject()
  if Tags != nil:
    formData_595195.add "Tags", Tags
  add(query_595194, "Action", newJString(Action))
  add(formData_595195, "ResourceArn", newJString(ResourceArn))
  add(query_595194, "Version", newJString(Version))
  result = call_595193.call(nil, query_595194, nil, formData_595195, nil)

var postTagResource* = Call_PostTagResource_595178(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_595179,
    base: "/", url: url_PostTagResource_595180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_595161 = ref object of OpenApiRestCall_593437
proc url_GetTagResource_595163(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagResource_595162(path: JsonNode; query: JsonNode;
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
  var valid_595164 = query.getOrDefault("ResourceArn")
  valid_595164 = validateParameter(valid_595164, JString, required = true,
                                 default = nil)
  if valid_595164 != nil:
    section.add "ResourceArn", valid_595164
  var valid_595165 = query.getOrDefault("Tags")
  valid_595165 = validateParameter(valid_595165, JArray, required = true, default = nil)
  if valid_595165 != nil:
    section.add "Tags", valid_595165
  var valid_595166 = query.getOrDefault("Action")
  valid_595166 = validateParameter(valid_595166, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_595166 != nil:
    section.add "Action", valid_595166
  var valid_595167 = query.getOrDefault("Version")
  valid_595167 = validateParameter(valid_595167, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595167 != nil:
    section.add "Version", valid_595167
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
  var valid_595168 = header.getOrDefault("X-Amz-Date")
  valid_595168 = validateParameter(valid_595168, JString, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "X-Amz-Date", valid_595168
  var valid_595169 = header.getOrDefault("X-Amz-Security-Token")
  valid_595169 = validateParameter(valid_595169, JString, required = false,
                                 default = nil)
  if valid_595169 != nil:
    section.add "X-Amz-Security-Token", valid_595169
  var valid_595170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595170 = validateParameter(valid_595170, JString, required = false,
                                 default = nil)
  if valid_595170 != nil:
    section.add "X-Amz-Content-Sha256", valid_595170
  var valid_595171 = header.getOrDefault("X-Amz-Algorithm")
  valid_595171 = validateParameter(valid_595171, JString, required = false,
                                 default = nil)
  if valid_595171 != nil:
    section.add "X-Amz-Algorithm", valid_595171
  var valid_595172 = header.getOrDefault("X-Amz-Signature")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "X-Amz-Signature", valid_595172
  var valid_595173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595173 = validateParameter(valid_595173, JString, required = false,
                                 default = nil)
  if valid_595173 != nil:
    section.add "X-Amz-SignedHeaders", valid_595173
  var valid_595174 = header.getOrDefault("X-Amz-Credential")
  valid_595174 = validateParameter(valid_595174, JString, required = false,
                                 default = nil)
  if valid_595174 != nil:
    section.add "X-Amz-Credential", valid_595174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595175: Call_GetTagResource_595161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_595175.validator(path, query, header, formData, body)
  let scheme = call_595175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595175.url(scheme.get, call_595175.host, call_595175.base,
                         call_595175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595175, url, valid)

proc call*(call_595176: Call_GetTagResource_595161; ResourceArn: string;
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
  var query_595177 = newJObject()
  add(query_595177, "ResourceArn", newJString(ResourceArn))
  if Tags != nil:
    query_595177.add "Tags", Tags
  add(query_595177, "Action", newJString(Action))
  add(query_595177, "Version", newJString(Version))
  result = call_595176.call(nil, query_595177, nil, nil, nil)

var getTagResource* = Call_GetTagResource_595161(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_595162,
    base: "/", url: url_GetTagResource_595163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_595212 = ref object of OpenApiRestCall_593437
proc url_PostUnsubscribe_595214(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUnsubscribe_595213(path: JsonNode; query: JsonNode;
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
  var valid_595215 = query.getOrDefault("Action")
  valid_595215 = validateParameter(valid_595215, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_595215 != nil:
    section.add "Action", valid_595215
  var valid_595216 = query.getOrDefault("Version")
  valid_595216 = validateParameter(valid_595216, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595216 != nil:
    section.add "Version", valid_595216
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
  var valid_595217 = header.getOrDefault("X-Amz-Date")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "X-Amz-Date", valid_595217
  var valid_595218 = header.getOrDefault("X-Amz-Security-Token")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "X-Amz-Security-Token", valid_595218
  var valid_595219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595219 = validateParameter(valid_595219, JString, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "X-Amz-Content-Sha256", valid_595219
  var valid_595220 = header.getOrDefault("X-Amz-Algorithm")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "X-Amz-Algorithm", valid_595220
  var valid_595221 = header.getOrDefault("X-Amz-Signature")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "X-Amz-Signature", valid_595221
  var valid_595222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595222 = validateParameter(valid_595222, JString, required = false,
                                 default = nil)
  if valid_595222 != nil:
    section.add "X-Amz-SignedHeaders", valid_595222
  var valid_595223 = header.getOrDefault("X-Amz-Credential")
  valid_595223 = validateParameter(valid_595223, JString, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "X-Amz-Credential", valid_595223
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_595224 = formData.getOrDefault("SubscriptionArn")
  valid_595224 = validateParameter(valid_595224, JString, required = true,
                                 default = nil)
  if valid_595224 != nil:
    section.add "SubscriptionArn", valid_595224
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595225: Call_PostUnsubscribe_595212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_595225.validator(path, query, header, formData, body)
  let scheme = call_595225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595225.url(scheme.get, call_595225.host, call_595225.base,
                         call_595225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595225, url, valid)

proc call*(call_595226: Call_PostUnsubscribe_595212; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Version: string (required)
  var query_595227 = newJObject()
  var formData_595228 = newJObject()
  add(query_595227, "Action", newJString(Action))
  add(formData_595228, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_595227, "Version", newJString(Version))
  result = call_595226.call(nil, query_595227, nil, formData_595228, nil)

var postUnsubscribe* = Call_PostUnsubscribe_595212(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_595213,
    base: "/", url: url_PostUnsubscribe_595214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_595196 = ref object of OpenApiRestCall_593437
proc url_GetUnsubscribe_595198(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUnsubscribe_595197(path: JsonNode; query: JsonNode;
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
  var valid_595199 = query.getOrDefault("SubscriptionArn")
  valid_595199 = validateParameter(valid_595199, JString, required = true,
                                 default = nil)
  if valid_595199 != nil:
    section.add "SubscriptionArn", valid_595199
  var valid_595200 = query.getOrDefault("Action")
  valid_595200 = validateParameter(valid_595200, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_595200 != nil:
    section.add "Action", valid_595200
  var valid_595201 = query.getOrDefault("Version")
  valid_595201 = validateParameter(valid_595201, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595201 != nil:
    section.add "Version", valid_595201
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
  var valid_595202 = header.getOrDefault("X-Amz-Date")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "X-Amz-Date", valid_595202
  var valid_595203 = header.getOrDefault("X-Amz-Security-Token")
  valid_595203 = validateParameter(valid_595203, JString, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "X-Amz-Security-Token", valid_595203
  var valid_595204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-Content-Sha256", valid_595204
  var valid_595205 = header.getOrDefault("X-Amz-Algorithm")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "X-Amz-Algorithm", valid_595205
  var valid_595206 = header.getOrDefault("X-Amz-Signature")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "X-Amz-Signature", valid_595206
  var valid_595207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595207 = validateParameter(valid_595207, JString, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "X-Amz-SignedHeaders", valid_595207
  var valid_595208 = header.getOrDefault("X-Amz-Credential")
  valid_595208 = validateParameter(valid_595208, JString, required = false,
                                 default = nil)
  if valid_595208 != nil:
    section.add "X-Amz-Credential", valid_595208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595209: Call_GetUnsubscribe_595196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_595209.validator(path, query, header, formData, body)
  let scheme = call_595209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595209.url(scheme.get, call_595209.host, call_595209.base,
                         call_595209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595209, url, valid)

proc call*(call_595210: Call_GetUnsubscribe_595196; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595211 = newJObject()
  add(query_595211, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_595211, "Action", newJString(Action))
  add(query_595211, "Version", newJString(Version))
  result = call_595210.call(nil, query_595211, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_595196(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_595197,
    base: "/", url: url_GetUnsubscribe_595198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_595246 = ref object of OpenApiRestCall_593437
proc url_PostUntagResource_595248(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUntagResource_595247(path: JsonNode; query: JsonNode;
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
  var valid_595249 = query.getOrDefault("Action")
  valid_595249 = validateParameter(valid_595249, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_595249 != nil:
    section.add "Action", valid_595249
  var valid_595250 = query.getOrDefault("Version")
  valid_595250 = validateParameter(valid_595250, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595250 != nil:
    section.add "Version", valid_595250
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
  var valid_595251 = header.getOrDefault("X-Amz-Date")
  valid_595251 = validateParameter(valid_595251, JString, required = false,
                                 default = nil)
  if valid_595251 != nil:
    section.add "X-Amz-Date", valid_595251
  var valid_595252 = header.getOrDefault("X-Amz-Security-Token")
  valid_595252 = validateParameter(valid_595252, JString, required = false,
                                 default = nil)
  if valid_595252 != nil:
    section.add "X-Amz-Security-Token", valid_595252
  var valid_595253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Content-Sha256", valid_595253
  var valid_595254 = header.getOrDefault("X-Amz-Algorithm")
  valid_595254 = validateParameter(valid_595254, JString, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "X-Amz-Algorithm", valid_595254
  var valid_595255 = header.getOrDefault("X-Amz-Signature")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "X-Amz-Signature", valid_595255
  var valid_595256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595256 = validateParameter(valid_595256, JString, required = false,
                                 default = nil)
  if valid_595256 != nil:
    section.add "X-Amz-SignedHeaders", valid_595256
  var valid_595257 = header.getOrDefault("X-Amz-Credential")
  valid_595257 = validateParameter(valid_595257, JString, required = false,
                                 default = nil)
  if valid_595257 != nil:
    section.add "X-Amz-Credential", valid_595257
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_595258 = formData.getOrDefault("TagKeys")
  valid_595258 = validateParameter(valid_595258, JArray, required = true, default = nil)
  if valid_595258 != nil:
    section.add "TagKeys", valid_595258
  var valid_595259 = formData.getOrDefault("ResourceArn")
  valid_595259 = validateParameter(valid_595259, JString, required = true,
                                 default = nil)
  if valid_595259 != nil:
    section.add "ResourceArn", valid_595259
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595260: Call_PostUntagResource_595246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_595260.validator(path, query, header, formData, body)
  let scheme = call_595260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595260.url(scheme.get, call_595260.host, call_595260.base,
                         call_595260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595260, url, valid)

proc call*(call_595261: Call_PostUntagResource_595246; TagKeys: JsonNode;
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
  var query_595262 = newJObject()
  var formData_595263 = newJObject()
  add(query_595262, "Action", newJString(Action))
  if TagKeys != nil:
    formData_595263.add "TagKeys", TagKeys
  add(formData_595263, "ResourceArn", newJString(ResourceArn))
  add(query_595262, "Version", newJString(Version))
  result = call_595261.call(nil, query_595262, nil, formData_595263, nil)

var postUntagResource* = Call_PostUntagResource_595246(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_595247,
    base: "/", url: url_PostUntagResource_595248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_595229 = ref object of OpenApiRestCall_593437
proc url_GetUntagResource_595231(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUntagResource_595230(path: JsonNode; query: JsonNode;
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
  var valid_595232 = query.getOrDefault("ResourceArn")
  valid_595232 = validateParameter(valid_595232, JString, required = true,
                                 default = nil)
  if valid_595232 != nil:
    section.add "ResourceArn", valid_595232
  var valid_595233 = query.getOrDefault("Action")
  valid_595233 = validateParameter(valid_595233, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_595233 != nil:
    section.add "Action", valid_595233
  var valid_595234 = query.getOrDefault("TagKeys")
  valid_595234 = validateParameter(valid_595234, JArray, required = true, default = nil)
  if valid_595234 != nil:
    section.add "TagKeys", valid_595234
  var valid_595235 = query.getOrDefault("Version")
  valid_595235 = validateParameter(valid_595235, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_595235 != nil:
    section.add "Version", valid_595235
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
  var valid_595236 = header.getOrDefault("X-Amz-Date")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "X-Amz-Date", valid_595236
  var valid_595237 = header.getOrDefault("X-Amz-Security-Token")
  valid_595237 = validateParameter(valid_595237, JString, required = false,
                                 default = nil)
  if valid_595237 != nil:
    section.add "X-Amz-Security-Token", valid_595237
  var valid_595238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595238 = validateParameter(valid_595238, JString, required = false,
                                 default = nil)
  if valid_595238 != nil:
    section.add "X-Amz-Content-Sha256", valid_595238
  var valid_595239 = header.getOrDefault("X-Amz-Algorithm")
  valid_595239 = validateParameter(valid_595239, JString, required = false,
                                 default = nil)
  if valid_595239 != nil:
    section.add "X-Amz-Algorithm", valid_595239
  var valid_595240 = header.getOrDefault("X-Amz-Signature")
  valid_595240 = validateParameter(valid_595240, JString, required = false,
                                 default = nil)
  if valid_595240 != nil:
    section.add "X-Amz-Signature", valid_595240
  var valid_595241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595241 = validateParameter(valid_595241, JString, required = false,
                                 default = nil)
  if valid_595241 != nil:
    section.add "X-Amz-SignedHeaders", valid_595241
  var valid_595242 = header.getOrDefault("X-Amz-Credential")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "X-Amz-Credential", valid_595242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595243: Call_GetUntagResource_595229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_595243.validator(path, query, header, formData, body)
  let scheme = call_595243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595243.url(scheme.get, call_595243.host, call_595243.base,
                         call_595243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595243, url, valid)

proc call*(call_595244: Call_GetUntagResource_595229; ResourceArn: string;
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
  var query_595245 = newJObject()
  add(query_595245, "ResourceArn", newJString(ResourceArn))
  add(query_595245, "Action", newJString(Action))
  if TagKeys != nil:
    query_595245.add "TagKeys", TagKeys
  add(query_595245, "Version", newJString(Version))
  result = call_595244.call(nil, query_595245, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_595229(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_595230,
    base: "/", url: url_GetUntagResource_595231,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
