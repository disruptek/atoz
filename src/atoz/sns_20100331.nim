
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  Call_PostAddPermission_603077 = ref object of OpenApiRestCall_602466
proc url_PostAddPermission_603079(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddPermission_603078(path: JsonNode; query: JsonNode;
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
  var valid_603080 = query.getOrDefault("Action")
  valid_603080 = validateParameter(valid_603080, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_603080 != nil:
    section.add "Action", valid_603080
  var valid_603081 = query.getOrDefault("Version")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603081 != nil:
    section.add "Version", valid_603081
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
  var valid_603082 = header.getOrDefault("X-Amz-Date")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Date", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Security-Token")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Security-Token", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Content-Sha256", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Algorithm")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Algorithm", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Signature")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Signature", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-SignedHeaders", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Credential")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Credential", valid_603088
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
  var valid_603089 = formData.getOrDefault("TopicArn")
  valid_603089 = validateParameter(valid_603089, JString, required = true,
                                 default = nil)
  if valid_603089 != nil:
    section.add "TopicArn", valid_603089
  var valid_603090 = formData.getOrDefault("AWSAccountId")
  valid_603090 = validateParameter(valid_603090, JArray, required = true, default = nil)
  if valid_603090 != nil:
    section.add "AWSAccountId", valid_603090
  var valid_603091 = formData.getOrDefault("Label")
  valid_603091 = validateParameter(valid_603091, JString, required = true,
                                 default = nil)
  if valid_603091 != nil:
    section.add "Label", valid_603091
  var valid_603092 = formData.getOrDefault("ActionName")
  valid_603092 = validateParameter(valid_603092, JArray, required = true, default = nil)
  if valid_603092 != nil:
    section.add "ActionName", valid_603092
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603093: Call_PostAddPermission_603077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_603093.validator(path, query, header, formData, body)
  let scheme = call_603093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603093.url(scheme.get, call_603093.host, call_603093.base,
                         call_603093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603093, url, valid)

proc call*(call_603094: Call_PostAddPermission_603077; TopicArn: string;
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
  var query_603095 = newJObject()
  var formData_603096 = newJObject()
  add(formData_603096, "TopicArn", newJString(TopicArn))
  if AWSAccountId != nil:
    formData_603096.add "AWSAccountId", AWSAccountId
  add(formData_603096, "Label", newJString(Label))
  add(query_603095, "Action", newJString(Action))
  if ActionName != nil:
    formData_603096.add "ActionName", ActionName
  add(query_603095, "Version", newJString(Version))
  result = call_603094.call(nil, query_603095, nil, formData_603096, nil)

var postAddPermission* = Call_PostAddPermission_603077(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_603078,
    base: "/", url: url_PostAddPermission_603079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_602803 = ref object of OpenApiRestCall_602466
proc url_GetAddPermission_602805(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddPermission_602804(path: JsonNode; query: JsonNode;
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
  var valid_602917 = query.getOrDefault("ActionName")
  valid_602917 = validateParameter(valid_602917, JArray, required = true, default = nil)
  if valid_602917 != nil:
    section.add "ActionName", valid_602917
  var valid_602931 = query.getOrDefault("Action")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_602931 != nil:
    section.add "Action", valid_602931
  var valid_602932 = query.getOrDefault("TopicArn")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = nil)
  if valid_602932 != nil:
    section.add "TopicArn", valid_602932
  var valid_602933 = query.getOrDefault("Version")
  valid_602933 = validateParameter(valid_602933, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602933 != nil:
    section.add "Version", valid_602933
  var valid_602934 = query.getOrDefault("Label")
  valid_602934 = validateParameter(valid_602934, JString, required = true,
                                 default = nil)
  if valid_602934 != nil:
    section.add "Label", valid_602934
  var valid_602935 = query.getOrDefault("AWSAccountId")
  valid_602935 = validateParameter(valid_602935, JArray, required = true, default = nil)
  if valid_602935 != nil:
    section.add "AWSAccountId", valid_602935
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
  var valid_602936 = header.getOrDefault("X-Amz-Date")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Date", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Security-Token")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Security-Token", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Content-Sha256", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Algorithm")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Algorithm", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Signature")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Signature", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-SignedHeaders", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Credential")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Credential", valid_602942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602965: Call_GetAddPermission_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_602965.validator(path, query, header, formData, body)
  let scheme = call_602965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602965.url(scheme.get, call_602965.host, call_602965.base,
                         call_602965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602965, url, valid)

proc call*(call_603036: Call_GetAddPermission_602803; ActionName: JsonNode;
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
  var query_603037 = newJObject()
  if ActionName != nil:
    query_603037.add "ActionName", ActionName
  add(query_603037, "Action", newJString(Action))
  add(query_603037, "TopicArn", newJString(TopicArn))
  add(query_603037, "Version", newJString(Version))
  add(query_603037, "Label", newJString(Label))
  if AWSAccountId != nil:
    query_603037.add "AWSAccountId", AWSAccountId
  result = call_603036.call(nil, query_603037, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_602803(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_602804,
    base: "/", url: url_GetAddPermission_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_603113 = ref object of OpenApiRestCall_602466
proc url_PostCheckIfPhoneNumberIsOptedOut_603115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCheckIfPhoneNumberIsOptedOut_603114(path: JsonNode;
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
  var valid_603116 = query.getOrDefault("Action")
  valid_603116 = validateParameter(valid_603116, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_603116 != nil:
    section.add "Action", valid_603116
  var valid_603117 = query.getOrDefault("Version")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603117 != nil:
    section.add "Version", valid_603117
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
  var valid_603118 = header.getOrDefault("X-Amz-Date")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Date", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Security-Token")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Security-Token", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Content-Sha256", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Signature")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Signature", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-SignedHeaders", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_603125 = formData.getOrDefault("phoneNumber")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "phoneNumber", valid_603125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_PostCheckIfPhoneNumberIsOptedOut_603113;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_PostCheckIfPhoneNumberIsOptedOut_603113;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Version: string (required)
  var query_603128 = newJObject()
  var formData_603129 = newJObject()
  add(query_603128, "Action", newJString(Action))
  add(formData_603129, "phoneNumber", newJString(phoneNumber))
  add(query_603128, "Version", newJString(Version))
  result = call_603127.call(nil, query_603128, nil, formData_603129, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_603113(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_603114, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_603115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_603097 = ref object of OpenApiRestCall_602466
proc url_GetCheckIfPhoneNumberIsOptedOut_603099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCheckIfPhoneNumberIsOptedOut_603098(path: JsonNode;
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
  var valid_603100 = query.getOrDefault("phoneNumber")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = nil)
  if valid_603100 != nil:
    section.add "phoneNumber", valid_603100
  var valid_603101 = query.getOrDefault("Action")
  valid_603101 = validateParameter(valid_603101, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_603101 != nil:
    section.add "Action", valid_603101
  var valid_603102 = query.getOrDefault("Version")
  valid_603102 = validateParameter(valid_603102, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603102 != nil:
    section.add "Version", valid_603102
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
  var valid_603103 = header.getOrDefault("X-Amz-Date")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Date", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Security-Token")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Security-Token", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Content-Sha256", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Signature")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Signature", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-SignedHeaders", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Credential")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Credential", valid_603109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603110: Call_GetCheckIfPhoneNumberIsOptedOut_603097;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_603110.validator(path, query, header, formData, body)
  let scheme = call_603110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603110.url(scheme.get, call_603110.host, call_603110.base,
                         call_603110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603110, url, valid)

proc call*(call_603111: Call_GetCheckIfPhoneNumberIsOptedOut_603097;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603112 = newJObject()
  add(query_603112, "phoneNumber", newJString(phoneNumber))
  add(query_603112, "Action", newJString(Action))
  add(query_603112, "Version", newJString(Version))
  result = call_603111.call(nil, query_603112, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_603097(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_603098, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_603099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_603148 = ref object of OpenApiRestCall_602466
proc url_PostConfirmSubscription_603150(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostConfirmSubscription_603149(path: JsonNode; query: JsonNode;
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
  var valid_603151 = query.getOrDefault("Action")
  valid_603151 = validateParameter(valid_603151, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_603151 != nil:
    section.add "Action", valid_603151
  var valid_603152 = query.getOrDefault("Version")
  valid_603152 = validateParameter(valid_603152, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603152 != nil:
    section.add "Version", valid_603152
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
  var valid_603153 = header.getOrDefault("X-Amz-Date")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Date", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Security-Token")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Security-Token", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Content-Sha256", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Algorithm")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Algorithm", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Signature")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Signature", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-SignedHeaders", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Credential")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Credential", valid_603159
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
  var valid_603160 = formData.getOrDefault("TopicArn")
  valid_603160 = validateParameter(valid_603160, JString, required = true,
                                 default = nil)
  if valid_603160 != nil:
    section.add "TopicArn", valid_603160
  var valid_603161 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_603161
  var valid_603162 = formData.getOrDefault("Token")
  valid_603162 = validateParameter(valid_603162, JString, required = true,
                                 default = nil)
  if valid_603162 != nil:
    section.add "Token", valid_603162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603163: Call_PostConfirmSubscription_603148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_603163.validator(path, query, header, formData, body)
  let scheme = call_603163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603163.url(scheme.get, call_603163.host, call_603163.base,
                         call_603163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603163, url, valid)

proc call*(call_603164: Call_PostConfirmSubscription_603148; TopicArn: string;
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
  var query_603165 = newJObject()
  var formData_603166 = newJObject()
  add(formData_603166, "TopicArn", newJString(TopicArn))
  add(formData_603166, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_603165, "Action", newJString(Action))
  add(query_603165, "Version", newJString(Version))
  add(formData_603166, "Token", newJString(Token))
  result = call_603164.call(nil, query_603165, nil, formData_603166, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_603148(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_603149, base: "/",
    url: url_PostConfirmSubscription_603150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_603130 = ref object of OpenApiRestCall_602466
proc url_GetConfirmSubscription_603132(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConfirmSubscription_603131(path: JsonNode; query: JsonNode;
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
  var valid_603133 = query.getOrDefault("Token")
  valid_603133 = validateParameter(valid_603133, JString, required = true,
                                 default = nil)
  if valid_603133 != nil:
    section.add "Token", valid_603133
  var valid_603134 = query.getOrDefault("Action")
  valid_603134 = validateParameter(valid_603134, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_603134 != nil:
    section.add "Action", valid_603134
  var valid_603135 = query.getOrDefault("TopicArn")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = nil)
  if valid_603135 != nil:
    section.add "TopicArn", valid_603135
  var valid_603136 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_603136
  var valid_603137 = query.getOrDefault("Version")
  valid_603137 = validateParameter(valid_603137, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603137 != nil:
    section.add "Version", valid_603137
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
  var valid_603138 = header.getOrDefault("X-Amz-Date")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Date", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Security-Token")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Security-Token", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Content-Sha256", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Algorithm")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Algorithm", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Signature")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Signature", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-SignedHeaders", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Credential")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Credential", valid_603144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603145: Call_GetConfirmSubscription_603130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_603145.validator(path, query, header, formData, body)
  let scheme = call_603145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603145.url(scheme.get, call_603145.host, call_603145.base,
                         call_603145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603145, url, valid)

proc call*(call_603146: Call_GetConfirmSubscription_603130; Token: string;
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
  var query_603147 = newJObject()
  add(query_603147, "Token", newJString(Token))
  add(query_603147, "Action", newJString(Action))
  add(query_603147, "TopicArn", newJString(TopicArn))
  add(query_603147, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_603147, "Version", newJString(Version))
  result = call_603146.call(nil, query_603147, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_603130(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_603131, base: "/",
    url: url_GetConfirmSubscription_603132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_603190 = ref object of OpenApiRestCall_602466
proc url_PostCreatePlatformApplication_603192(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformApplication_603191(path: JsonNode; query: JsonNode;
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
  var valid_603193 = query.getOrDefault("Action")
  valid_603193 = validateParameter(valid_603193, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_603193 != nil:
    section.add "Action", valid_603193
  var valid_603194 = query.getOrDefault("Version")
  valid_603194 = validateParameter(valid_603194, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603194 != nil:
    section.add "Version", valid_603194
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Content-Sha256", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Algorithm")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Algorithm", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Signature")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Signature", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-SignedHeaders", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Credential")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Credential", valid_603201
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
  var valid_603202 = formData.getOrDefault("Name")
  valid_603202 = validateParameter(valid_603202, JString, required = true,
                                 default = nil)
  if valid_603202 != nil:
    section.add "Name", valid_603202
  var valid_603203 = formData.getOrDefault("Attributes.0.value")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "Attributes.0.value", valid_603203
  var valid_603204 = formData.getOrDefault("Attributes.0.key")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "Attributes.0.key", valid_603204
  var valid_603205 = formData.getOrDefault("Attributes.1.key")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "Attributes.1.key", valid_603205
  var valid_603206 = formData.getOrDefault("Attributes.2.value")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "Attributes.2.value", valid_603206
  var valid_603207 = formData.getOrDefault("Platform")
  valid_603207 = validateParameter(valid_603207, JString, required = true,
                                 default = nil)
  if valid_603207 != nil:
    section.add "Platform", valid_603207
  var valid_603208 = formData.getOrDefault("Attributes.2.key")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "Attributes.2.key", valid_603208
  var valid_603209 = formData.getOrDefault("Attributes.1.value")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "Attributes.1.value", valid_603209
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603210: Call_PostCreatePlatformApplication_603190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_603210.validator(path, query, header, formData, body)
  let scheme = call_603210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603210.url(scheme.get, call_603210.host, call_603210.base,
                         call_603210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603210, url, valid)

proc call*(call_603211: Call_PostCreatePlatformApplication_603190; Name: string;
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
  var query_603212 = newJObject()
  var formData_603213 = newJObject()
  add(formData_603213, "Name", newJString(Name))
  add(formData_603213, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603213, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_603213, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603212, "Action", newJString(Action))
  add(formData_603213, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603213, "Platform", newJString(Platform))
  add(formData_603213, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603212, "Version", newJString(Version))
  add(formData_603213, "Attributes.1.value", newJString(Attributes1Value))
  result = call_603211.call(nil, query_603212, nil, formData_603213, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_603190(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_603191, base: "/",
    url: url_PostCreatePlatformApplication_603192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_603167 = ref object of OpenApiRestCall_602466
proc url_GetCreatePlatformApplication_603169(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformApplication_603168(path: JsonNode; query: JsonNode;
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
  var valid_603170 = query.getOrDefault("Attributes.2.key")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "Attributes.2.key", valid_603170
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_603171 = query.getOrDefault("Name")
  valid_603171 = validateParameter(valid_603171, JString, required = true,
                                 default = nil)
  if valid_603171 != nil:
    section.add "Name", valid_603171
  var valid_603172 = query.getOrDefault("Attributes.1.value")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "Attributes.1.value", valid_603172
  var valid_603173 = query.getOrDefault("Attributes.0.value")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "Attributes.0.value", valid_603173
  var valid_603174 = query.getOrDefault("Action")
  valid_603174 = validateParameter(valid_603174, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_603174 != nil:
    section.add "Action", valid_603174
  var valid_603175 = query.getOrDefault("Attributes.1.key")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "Attributes.1.key", valid_603175
  var valid_603176 = query.getOrDefault("Platform")
  valid_603176 = validateParameter(valid_603176, JString, required = true,
                                 default = nil)
  if valid_603176 != nil:
    section.add "Platform", valid_603176
  var valid_603177 = query.getOrDefault("Attributes.2.value")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "Attributes.2.value", valid_603177
  var valid_603178 = query.getOrDefault("Attributes.0.key")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "Attributes.0.key", valid_603178
  var valid_603179 = query.getOrDefault("Version")
  valid_603179 = validateParameter(valid_603179, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603179 != nil:
    section.add "Version", valid_603179
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Content-Sha256", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Algorithm")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Algorithm", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Signature")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Signature", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-SignedHeaders", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Credential")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Credential", valid_603186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603187: Call_GetCreatePlatformApplication_603167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_603187.validator(path, query, header, formData, body)
  let scheme = call_603187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603187.url(scheme.get, call_603187.host, call_603187.base,
                         call_603187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603187, url, valid)

proc call*(call_603188: Call_GetCreatePlatformApplication_603167; Name: string;
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
  var query_603189 = newJObject()
  add(query_603189, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603189, "Name", newJString(Name))
  add(query_603189, "Attributes.1.value", newJString(Attributes1Value))
  add(query_603189, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603189, "Action", newJString(Action))
  add(query_603189, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603189, "Platform", newJString(Platform))
  add(query_603189, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603189, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603189, "Version", newJString(Version))
  result = call_603188.call(nil, query_603189, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_603167(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_603168, base: "/",
    url: url_GetCreatePlatformApplication_603169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_603238 = ref object of OpenApiRestCall_602466
proc url_PostCreatePlatformEndpoint_603240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformEndpoint_603239(path: JsonNode; query: JsonNode;
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
  var valid_603241 = query.getOrDefault("Action")
  valid_603241 = validateParameter(valid_603241, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_603241 != nil:
    section.add "Action", valid_603241
  var valid_603242 = query.getOrDefault("Version")
  valid_603242 = validateParameter(valid_603242, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603242 != nil:
    section.add "Version", valid_603242
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
  var valid_603243 = header.getOrDefault("X-Amz-Date")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Date", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Security-Token")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Security-Token", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Content-Sha256", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Algorithm")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Algorithm", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Signature")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Signature", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-SignedHeaders", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Credential")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Credential", valid_603249
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
  var valid_603250 = formData.getOrDefault("Attributes.0.value")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "Attributes.0.value", valid_603250
  var valid_603251 = formData.getOrDefault("Attributes.0.key")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "Attributes.0.key", valid_603251
  var valid_603252 = formData.getOrDefault("Attributes.1.key")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "Attributes.1.key", valid_603252
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_603253 = formData.getOrDefault("PlatformApplicationArn")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "PlatformApplicationArn", valid_603253
  var valid_603254 = formData.getOrDefault("CustomUserData")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "CustomUserData", valid_603254
  var valid_603255 = formData.getOrDefault("Attributes.2.value")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "Attributes.2.value", valid_603255
  var valid_603256 = formData.getOrDefault("Attributes.2.key")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "Attributes.2.key", valid_603256
  var valid_603257 = formData.getOrDefault("Attributes.1.value")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "Attributes.1.value", valid_603257
  var valid_603258 = formData.getOrDefault("Token")
  valid_603258 = validateParameter(valid_603258, JString, required = true,
                                 default = nil)
  if valid_603258 != nil:
    section.add "Token", valid_603258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603259: Call_PostCreatePlatformEndpoint_603238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_603259.validator(path, query, header, formData, body)
  let scheme = call_603259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603259.url(scheme.get, call_603259.host, call_603259.base,
                         call_603259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603259, url, valid)

proc call*(call_603260: Call_PostCreatePlatformEndpoint_603238;
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
  var query_603261 = newJObject()
  var formData_603262 = newJObject()
  add(formData_603262, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603262, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_603262, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603261, "Action", newJString(Action))
  add(formData_603262, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_603262, "CustomUserData", newJString(CustomUserData))
  add(formData_603262, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603262, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603261, "Version", newJString(Version))
  add(formData_603262, "Attributes.1.value", newJString(Attributes1Value))
  add(formData_603262, "Token", newJString(Token))
  result = call_603260.call(nil, query_603261, nil, formData_603262, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_603238(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_603239, base: "/",
    url: url_PostCreatePlatformEndpoint_603240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_603214 = ref object of OpenApiRestCall_602466
proc url_GetCreatePlatformEndpoint_603216(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformEndpoint_603215(path: JsonNode; query: JsonNode;
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
  var valid_603217 = query.getOrDefault("CustomUserData")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "CustomUserData", valid_603217
  var valid_603218 = query.getOrDefault("Attributes.2.key")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "Attributes.2.key", valid_603218
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_603219 = query.getOrDefault("Token")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = nil)
  if valid_603219 != nil:
    section.add "Token", valid_603219
  var valid_603220 = query.getOrDefault("Attributes.1.value")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "Attributes.1.value", valid_603220
  var valid_603221 = query.getOrDefault("Attributes.0.value")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "Attributes.0.value", valid_603221
  var valid_603222 = query.getOrDefault("Action")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_603222 != nil:
    section.add "Action", valid_603222
  var valid_603223 = query.getOrDefault("Attributes.1.key")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "Attributes.1.key", valid_603223
  var valid_603224 = query.getOrDefault("Attributes.2.value")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "Attributes.2.value", valid_603224
  var valid_603225 = query.getOrDefault("Attributes.0.key")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "Attributes.0.key", valid_603225
  var valid_603226 = query.getOrDefault("Version")
  valid_603226 = validateParameter(valid_603226, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603226 != nil:
    section.add "Version", valid_603226
  var valid_603227 = query.getOrDefault("PlatformApplicationArn")
  valid_603227 = validateParameter(valid_603227, JString, required = true,
                                 default = nil)
  if valid_603227 != nil:
    section.add "PlatformApplicationArn", valid_603227
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
  var valid_603228 = header.getOrDefault("X-Amz-Date")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Date", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Security-Token")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Security-Token", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Content-Sha256", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Algorithm")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Algorithm", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Signature")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Signature", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-SignedHeaders", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Credential")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Credential", valid_603234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603235: Call_GetCreatePlatformEndpoint_603214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_603235.validator(path, query, header, formData, body)
  let scheme = call_603235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603235.url(scheme.get, call_603235.host, call_603235.base,
                         call_603235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603235, url, valid)

proc call*(call_603236: Call_GetCreatePlatformEndpoint_603214; Token: string;
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
  var query_603237 = newJObject()
  add(query_603237, "CustomUserData", newJString(CustomUserData))
  add(query_603237, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603237, "Token", newJString(Token))
  add(query_603237, "Attributes.1.value", newJString(Attributes1Value))
  add(query_603237, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603237, "Action", newJString(Action))
  add(query_603237, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603237, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603237, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603237, "Version", newJString(Version))
  add(query_603237, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603236.call(nil, query_603237, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_603214(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_603215, base: "/",
    url: url_GetCreatePlatformEndpoint_603216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_603286 = ref object of OpenApiRestCall_602466
proc url_PostCreateTopic_603288(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateTopic_603287(path: JsonNode; query: JsonNode;
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
  var valid_603289 = query.getOrDefault("Action")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_603289 != nil:
    section.add "Action", valid_603289
  var valid_603290 = query.getOrDefault("Version")
  valid_603290 = validateParameter(valid_603290, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603290 != nil:
    section.add "Version", valid_603290
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
  var valid_603291 = header.getOrDefault("X-Amz-Date")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Date", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Security-Token")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Security-Token", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Content-Sha256", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Algorithm")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Algorithm", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Signature")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Signature", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-SignedHeaders", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Credential")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Credential", valid_603297
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
  var valid_603298 = formData.getOrDefault("Name")
  valid_603298 = validateParameter(valid_603298, JString, required = true,
                                 default = nil)
  if valid_603298 != nil:
    section.add "Name", valid_603298
  var valid_603299 = formData.getOrDefault("Attributes.0.value")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "Attributes.0.value", valid_603299
  var valid_603300 = formData.getOrDefault("Attributes.0.key")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "Attributes.0.key", valid_603300
  var valid_603301 = formData.getOrDefault("Tags")
  valid_603301 = validateParameter(valid_603301, JArray, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "Tags", valid_603301
  var valid_603302 = formData.getOrDefault("Attributes.1.key")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "Attributes.1.key", valid_603302
  var valid_603303 = formData.getOrDefault("Attributes.2.value")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "Attributes.2.value", valid_603303
  var valid_603304 = formData.getOrDefault("Attributes.2.key")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "Attributes.2.key", valid_603304
  var valid_603305 = formData.getOrDefault("Attributes.1.value")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "Attributes.1.value", valid_603305
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603306: Call_PostCreateTopic_603286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_603306.validator(path, query, header, formData, body)
  let scheme = call_603306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603306.url(scheme.get, call_603306.host, call_603306.base,
                         call_603306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603306, url, valid)

proc call*(call_603307: Call_PostCreateTopic_603286; Name: string;
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
  var query_603308 = newJObject()
  var formData_603309 = newJObject()
  add(formData_603309, "Name", newJString(Name))
  add(formData_603309, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603309, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    formData_603309.add "Tags", Tags
  add(formData_603309, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603308, "Action", newJString(Action))
  add(formData_603309, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603309, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603308, "Version", newJString(Version))
  add(formData_603309, "Attributes.1.value", newJString(Attributes1Value))
  result = call_603307.call(nil, query_603308, nil, formData_603309, nil)

var postCreateTopic* = Call_PostCreateTopic_603286(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_603287,
    base: "/", url: url_PostCreateTopic_603288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_603263 = ref object of OpenApiRestCall_602466
proc url_GetCreateTopic_603265(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateTopic_603264(path: JsonNode; query: JsonNode;
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
  var valid_603266 = query.getOrDefault("Attributes.2.key")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "Attributes.2.key", valid_603266
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_603267 = query.getOrDefault("Name")
  valid_603267 = validateParameter(valid_603267, JString, required = true,
                                 default = nil)
  if valid_603267 != nil:
    section.add "Name", valid_603267
  var valid_603268 = query.getOrDefault("Attributes.1.value")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "Attributes.1.value", valid_603268
  var valid_603269 = query.getOrDefault("Tags")
  valid_603269 = validateParameter(valid_603269, JArray, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "Tags", valid_603269
  var valid_603270 = query.getOrDefault("Attributes.0.value")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "Attributes.0.value", valid_603270
  var valid_603271 = query.getOrDefault("Action")
  valid_603271 = validateParameter(valid_603271, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_603271 != nil:
    section.add "Action", valid_603271
  var valid_603272 = query.getOrDefault("Attributes.1.key")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "Attributes.1.key", valid_603272
  var valid_603273 = query.getOrDefault("Attributes.2.value")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "Attributes.2.value", valid_603273
  var valid_603274 = query.getOrDefault("Attributes.0.key")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "Attributes.0.key", valid_603274
  var valid_603275 = query.getOrDefault("Version")
  valid_603275 = validateParameter(valid_603275, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603275 != nil:
    section.add "Version", valid_603275
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
  var valid_603276 = header.getOrDefault("X-Amz-Date")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Date", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Security-Token")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Security-Token", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Content-Sha256", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Algorithm")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Algorithm", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Signature")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Signature", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-SignedHeaders", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Credential")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Credential", valid_603282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603283: Call_GetCreateTopic_603263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_603283.validator(path, query, header, formData, body)
  let scheme = call_603283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603283.url(scheme.get, call_603283.host, call_603283.base,
                         call_603283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603283, url, valid)

proc call*(call_603284: Call_GetCreateTopic_603263; Name: string;
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
  var query_603285 = newJObject()
  add(query_603285, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603285, "Name", newJString(Name))
  add(query_603285, "Attributes.1.value", newJString(Attributes1Value))
  if Tags != nil:
    query_603285.add "Tags", Tags
  add(query_603285, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603285, "Action", newJString(Action))
  add(query_603285, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603285, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603285, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603285, "Version", newJString(Version))
  result = call_603284.call(nil, query_603285, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_603263(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_603264,
    base: "/", url: url_GetCreateTopic_603265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_603326 = ref object of OpenApiRestCall_602466
proc url_PostDeleteEndpoint_603328(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEndpoint_603327(path: JsonNode; query: JsonNode;
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
  var valid_603329 = query.getOrDefault("Action")
  valid_603329 = validateParameter(valid_603329, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_603329 != nil:
    section.add "Action", valid_603329
  var valid_603330 = query.getOrDefault("Version")
  valid_603330 = validateParameter(valid_603330, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603330 != nil:
    section.add "Version", valid_603330
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
  var valid_603331 = header.getOrDefault("X-Amz-Date")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Date", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Security-Token")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Security-Token", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_603338 = formData.getOrDefault("EndpointArn")
  valid_603338 = validateParameter(valid_603338, JString, required = true,
                                 default = nil)
  if valid_603338 != nil:
    section.add "EndpointArn", valid_603338
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_PostDeleteEndpoint_603326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_PostDeleteEndpoint_603326; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_603341 = newJObject()
  var formData_603342 = newJObject()
  add(query_603341, "Action", newJString(Action))
  add(formData_603342, "EndpointArn", newJString(EndpointArn))
  add(query_603341, "Version", newJString(Version))
  result = call_603340.call(nil, query_603341, nil, formData_603342, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_603326(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_603327, base: "/",
    url: url_PostDeleteEndpoint_603328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_603310 = ref object of OpenApiRestCall_602466
proc url_GetDeleteEndpoint_603312(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEndpoint_603311(path: JsonNode; query: JsonNode;
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
  var valid_603313 = query.getOrDefault("EndpointArn")
  valid_603313 = validateParameter(valid_603313, JString, required = true,
                                 default = nil)
  if valid_603313 != nil:
    section.add "EndpointArn", valid_603313
  var valid_603314 = query.getOrDefault("Action")
  valid_603314 = validateParameter(valid_603314, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_603314 != nil:
    section.add "Action", valid_603314
  var valid_603315 = query.getOrDefault("Version")
  valid_603315 = validateParameter(valid_603315, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603315 != nil:
    section.add "Version", valid_603315
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
  var valid_603316 = header.getOrDefault("X-Amz-Date")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Date", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Security-Token")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Security-Token", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603323: Call_GetDeleteEndpoint_603310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_603323.validator(path, query, header, formData, body)
  let scheme = call_603323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603323.url(scheme.get, call_603323.host, call_603323.base,
                         call_603323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603323, url, valid)

proc call*(call_603324: Call_GetDeleteEndpoint_603310; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603325 = newJObject()
  add(query_603325, "EndpointArn", newJString(EndpointArn))
  add(query_603325, "Action", newJString(Action))
  add(query_603325, "Version", newJString(Version))
  result = call_603324.call(nil, query_603325, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_603310(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_603311,
    base: "/", url: url_GetDeleteEndpoint_603312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_603359 = ref object of OpenApiRestCall_602466
proc url_PostDeletePlatformApplication_603361(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeletePlatformApplication_603360(path: JsonNode; query: JsonNode;
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
  var valid_603362 = query.getOrDefault("Action")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_603362 != nil:
    section.add "Action", valid_603362
  var valid_603363 = query.getOrDefault("Version")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603363 != nil:
    section.add "Version", valid_603363
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
  var valid_603364 = header.getOrDefault("X-Amz-Date")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Date", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Security-Token")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Security-Token", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Algorithm")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Algorithm", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Signature")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Signature", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-SignedHeaders", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Credential")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Credential", valid_603370
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_603371 = formData.getOrDefault("PlatformApplicationArn")
  valid_603371 = validateParameter(valid_603371, JString, required = true,
                                 default = nil)
  if valid_603371 != nil:
    section.add "PlatformApplicationArn", valid_603371
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603372: Call_PostDeletePlatformApplication_603359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603372.validator(path, query, header, formData, body)
  let scheme = call_603372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603372.url(scheme.get, call_603372.host, call_603372.base,
                         call_603372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603372, url, valid)

proc call*(call_603373: Call_PostDeletePlatformApplication_603359;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Version: string (required)
  var query_603374 = newJObject()
  var formData_603375 = newJObject()
  add(query_603374, "Action", newJString(Action))
  add(formData_603375, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_603374, "Version", newJString(Version))
  result = call_603373.call(nil, query_603374, nil, formData_603375, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_603359(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_603360, base: "/",
    url: url_PostDeletePlatformApplication_603361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_603343 = ref object of OpenApiRestCall_602466
proc url_GetDeletePlatformApplication_603345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeletePlatformApplication_603344(path: JsonNode; query: JsonNode;
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
  var valid_603346 = query.getOrDefault("Action")
  valid_603346 = validateParameter(valid_603346, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_603346 != nil:
    section.add "Action", valid_603346
  var valid_603347 = query.getOrDefault("Version")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603347 != nil:
    section.add "Version", valid_603347
  var valid_603348 = query.getOrDefault("PlatformApplicationArn")
  valid_603348 = validateParameter(valid_603348, JString, required = true,
                                 default = nil)
  if valid_603348 != nil:
    section.add "PlatformApplicationArn", valid_603348
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
  var valid_603349 = header.getOrDefault("X-Amz-Date")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Date", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Security-Token")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Security-Token", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Content-Sha256", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Algorithm")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Algorithm", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Signature")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Signature", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-SignedHeaders", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Credential")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Credential", valid_603355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603356: Call_GetDeletePlatformApplication_603343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603356.validator(path, query, header, formData, body)
  let scheme = call_603356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603356.url(scheme.get, call_603356.host, call_603356.base,
                         call_603356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603356, url, valid)

proc call*(call_603357: Call_GetDeletePlatformApplication_603343;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  var query_603358 = newJObject()
  add(query_603358, "Action", newJString(Action))
  add(query_603358, "Version", newJString(Version))
  add(query_603358, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603357.call(nil, query_603358, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_603343(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_603344, base: "/",
    url: url_GetDeletePlatformApplication_603345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_603392 = ref object of OpenApiRestCall_602466
proc url_PostDeleteTopic_603394(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteTopic_603393(path: JsonNode; query: JsonNode;
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
  var valid_603395 = query.getOrDefault("Action")
  valid_603395 = validateParameter(valid_603395, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_603395 != nil:
    section.add "Action", valid_603395
  var valid_603396 = query.getOrDefault("Version")
  valid_603396 = validateParameter(valid_603396, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603396 != nil:
    section.add "Version", valid_603396
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
  var valid_603397 = header.getOrDefault("X-Amz-Date")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Date", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Security-Token")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Security-Token", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Content-Sha256", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Algorithm")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Algorithm", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Signature")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Signature", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-SignedHeaders", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Credential")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Credential", valid_603403
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603404 = formData.getOrDefault("TopicArn")
  valid_603404 = validateParameter(valid_603404, JString, required = true,
                                 default = nil)
  if valid_603404 != nil:
    section.add "TopicArn", valid_603404
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603405: Call_PostDeleteTopic_603392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_603405.validator(path, query, header, formData, body)
  let scheme = call_603405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603405.url(scheme.get, call_603405.host, call_603405.base,
                         call_603405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603405, url, valid)

proc call*(call_603406: Call_PostDeleteTopic_603392; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603407 = newJObject()
  var formData_603408 = newJObject()
  add(formData_603408, "TopicArn", newJString(TopicArn))
  add(query_603407, "Action", newJString(Action))
  add(query_603407, "Version", newJString(Version))
  result = call_603406.call(nil, query_603407, nil, formData_603408, nil)

var postDeleteTopic* = Call_PostDeleteTopic_603392(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_603393,
    base: "/", url: url_PostDeleteTopic_603394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_603376 = ref object of OpenApiRestCall_602466
proc url_GetDeleteTopic_603378(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteTopic_603377(path: JsonNode; query: JsonNode;
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
  var valid_603379 = query.getOrDefault("Action")
  valid_603379 = validateParameter(valid_603379, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_603379 != nil:
    section.add "Action", valid_603379
  var valid_603380 = query.getOrDefault("TopicArn")
  valid_603380 = validateParameter(valid_603380, JString, required = true,
                                 default = nil)
  if valid_603380 != nil:
    section.add "TopicArn", valid_603380
  var valid_603381 = query.getOrDefault("Version")
  valid_603381 = validateParameter(valid_603381, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603381 != nil:
    section.add "Version", valid_603381
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
  var valid_603382 = header.getOrDefault("X-Amz-Date")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Date", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Security-Token")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Security-Token", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Content-Sha256", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Algorithm")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Algorithm", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Signature")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Signature", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-SignedHeaders", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Credential")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Credential", valid_603388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603389: Call_GetDeleteTopic_603376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_603389.validator(path, query, header, formData, body)
  let scheme = call_603389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603389.url(scheme.get, call_603389.host, call_603389.base,
                         call_603389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603389, url, valid)

proc call*(call_603390: Call_GetDeleteTopic_603376; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: string (required)
  var query_603391 = newJObject()
  add(query_603391, "Action", newJString(Action))
  add(query_603391, "TopicArn", newJString(TopicArn))
  add(query_603391, "Version", newJString(Version))
  result = call_603390.call(nil, query_603391, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_603376(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_603377,
    base: "/", url: url_GetDeleteTopic_603378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_603425 = ref object of OpenApiRestCall_602466
proc url_PostGetEndpointAttributes_603427(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetEndpointAttributes_603426(path: JsonNode; query: JsonNode;
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
  var valid_603428 = query.getOrDefault("Action")
  valid_603428 = validateParameter(valid_603428, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_603428 != nil:
    section.add "Action", valid_603428
  var valid_603429 = query.getOrDefault("Version")
  valid_603429 = validateParameter(valid_603429, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603429 != nil:
    section.add "Version", valid_603429
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
  var valid_603430 = header.getOrDefault("X-Amz-Date")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Date", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Security-Token")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Security-Token", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Content-Sha256", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Algorithm")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Algorithm", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Signature")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Signature", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-SignedHeaders", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Credential")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Credential", valid_603436
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_603437 = formData.getOrDefault("EndpointArn")
  valid_603437 = validateParameter(valid_603437, JString, required = true,
                                 default = nil)
  if valid_603437 != nil:
    section.add "EndpointArn", valid_603437
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603438: Call_PostGetEndpointAttributes_603425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603438.validator(path, query, header, formData, body)
  let scheme = call_603438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603438.url(scheme.get, call_603438.host, call_603438.base,
                         call_603438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603438, url, valid)

proc call*(call_603439: Call_PostGetEndpointAttributes_603425; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_603440 = newJObject()
  var formData_603441 = newJObject()
  add(query_603440, "Action", newJString(Action))
  add(formData_603441, "EndpointArn", newJString(EndpointArn))
  add(query_603440, "Version", newJString(Version))
  result = call_603439.call(nil, query_603440, nil, formData_603441, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_603425(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_603426, base: "/",
    url: url_PostGetEndpointAttributes_603427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_603409 = ref object of OpenApiRestCall_602466
proc url_GetGetEndpointAttributes_603411(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetEndpointAttributes_603410(path: JsonNode; query: JsonNode;
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
  var valid_603412 = query.getOrDefault("EndpointArn")
  valid_603412 = validateParameter(valid_603412, JString, required = true,
                                 default = nil)
  if valid_603412 != nil:
    section.add "EndpointArn", valid_603412
  var valid_603413 = query.getOrDefault("Action")
  valid_603413 = validateParameter(valid_603413, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_603413 != nil:
    section.add "Action", valid_603413
  var valid_603414 = query.getOrDefault("Version")
  valid_603414 = validateParameter(valid_603414, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603414 != nil:
    section.add "Version", valid_603414
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
  var valid_603415 = header.getOrDefault("X-Amz-Date")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Date", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Security-Token")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Security-Token", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Content-Sha256", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Algorithm")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Algorithm", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Signature")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Signature", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-SignedHeaders", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Credential")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Credential", valid_603421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603422: Call_GetGetEndpointAttributes_603409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603422.validator(path, query, header, formData, body)
  let scheme = call_603422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603422.url(scheme.get, call_603422.host, call_603422.base,
                         call_603422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603422, url, valid)

proc call*(call_603423: Call_GetGetEndpointAttributes_603409; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603424 = newJObject()
  add(query_603424, "EndpointArn", newJString(EndpointArn))
  add(query_603424, "Action", newJString(Action))
  add(query_603424, "Version", newJString(Version))
  result = call_603423.call(nil, query_603424, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_603409(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_603410, base: "/",
    url: url_GetGetEndpointAttributes_603411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_603458 = ref object of OpenApiRestCall_602466
proc url_PostGetPlatformApplicationAttributes_603460(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetPlatformApplicationAttributes_603459(path: JsonNode;
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
  var valid_603461 = query.getOrDefault("Action")
  valid_603461 = validateParameter(valid_603461, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_603461 != nil:
    section.add "Action", valid_603461
  var valid_603462 = query.getOrDefault("Version")
  valid_603462 = validateParameter(valid_603462, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603462 != nil:
    section.add "Version", valid_603462
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
  var valid_603463 = header.getOrDefault("X-Amz-Date")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Date", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Security-Token")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Security-Token", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Content-Sha256", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Algorithm")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Algorithm", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Signature")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Signature", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-SignedHeaders", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Credential")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Credential", valid_603469
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_603470 = formData.getOrDefault("PlatformApplicationArn")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = nil)
  if valid_603470 != nil:
    section.add "PlatformApplicationArn", valid_603470
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603471: Call_PostGetPlatformApplicationAttributes_603458;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603471.validator(path, query, header, formData, body)
  let scheme = call_603471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603471.url(scheme.get, call_603471.host, call_603471.base,
                         call_603471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603471, url, valid)

proc call*(call_603472: Call_PostGetPlatformApplicationAttributes_603458;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Version: string (required)
  var query_603473 = newJObject()
  var formData_603474 = newJObject()
  add(query_603473, "Action", newJString(Action))
  add(formData_603474, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_603473, "Version", newJString(Version))
  result = call_603472.call(nil, query_603473, nil, formData_603474, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_603458(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_603459, base: "/",
    url: url_PostGetPlatformApplicationAttributes_603460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_603442 = ref object of OpenApiRestCall_602466
proc url_GetGetPlatformApplicationAttributes_603444(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetPlatformApplicationAttributes_603443(path: JsonNode;
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
  var valid_603445 = query.getOrDefault("Action")
  valid_603445 = validateParameter(valid_603445, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_603445 != nil:
    section.add "Action", valid_603445
  var valid_603446 = query.getOrDefault("Version")
  valid_603446 = validateParameter(valid_603446, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603446 != nil:
    section.add "Version", valid_603446
  var valid_603447 = query.getOrDefault("PlatformApplicationArn")
  valid_603447 = validateParameter(valid_603447, JString, required = true,
                                 default = nil)
  if valid_603447 != nil:
    section.add "PlatformApplicationArn", valid_603447
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
  var valid_603448 = header.getOrDefault("X-Amz-Date")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Date", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Security-Token")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Security-Token", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Content-Sha256", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Algorithm")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Algorithm", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Signature")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Signature", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-SignedHeaders", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Credential")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Credential", valid_603454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603455: Call_GetGetPlatformApplicationAttributes_603442;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603455.validator(path, query, header, formData, body)
  let scheme = call_603455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603455.url(scheme.get, call_603455.host, call_603455.base,
                         call_603455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603455, url, valid)

proc call*(call_603456: Call_GetGetPlatformApplicationAttributes_603442;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  var query_603457 = newJObject()
  add(query_603457, "Action", newJString(Action))
  add(query_603457, "Version", newJString(Version))
  add(query_603457, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603456.call(nil, query_603457, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_603442(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_603443, base: "/",
    url: url_GetGetPlatformApplicationAttributes_603444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_603491 = ref object of OpenApiRestCall_602466
proc url_PostGetSMSAttributes_603493(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetSMSAttributes_603492(path: JsonNode; query: JsonNode;
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
  var valid_603494 = query.getOrDefault("Action")
  valid_603494 = validateParameter(valid_603494, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_603494 != nil:
    section.add "Action", valid_603494
  var valid_603495 = query.getOrDefault("Version")
  valid_603495 = validateParameter(valid_603495, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603495 != nil:
    section.add "Version", valid_603495
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
  var valid_603496 = header.getOrDefault("X-Amz-Date")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Date", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Security-Token")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Security-Token", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Content-Sha256", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Algorithm")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Algorithm", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Credential")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Credential", valid_603502
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_603503 = formData.getOrDefault("attributes")
  valid_603503 = validateParameter(valid_603503, JArray, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "attributes", valid_603503
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_PostGetSMSAttributes_603491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603504, url, valid)

proc call*(call_603505: Call_PostGetSMSAttributes_603491;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603506 = newJObject()
  var formData_603507 = newJObject()
  if attributes != nil:
    formData_603507.add "attributes", attributes
  add(query_603506, "Action", newJString(Action))
  add(query_603506, "Version", newJString(Version))
  result = call_603505.call(nil, query_603506, nil, formData_603507, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_603491(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_603492, base: "/",
    url: url_PostGetSMSAttributes_603493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_603475 = ref object of OpenApiRestCall_602466
proc url_GetGetSMSAttributes_603477(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetSMSAttributes_603476(path: JsonNode; query: JsonNode;
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
  var valid_603478 = query.getOrDefault("attributes")
  valid_603478 = validateParameter(valid_603478, JArray, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "attributes", valid_603478
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603479 = query.getOrDefault("Action")
  valid_603479 = validateParameter(valid_603479, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_603479 != nil:
    section.add "Action", valid_603479
  var valid_603480 = query.getOrDefault("Version")
  valid_603480 = validateParameter(valid_603480, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603480 != nil:
    section.add "Version", valid_603480
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
  var valid_603481 = header.getOrDefault("X-Amz-Date")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Date", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Security-Token")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Security-Token", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Content-Sha256", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Algorithm")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Algorithm", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Signature")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Signature", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-SignedHeaders", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Credential")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Credential", valid_603487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603488: Call_GetGetSMSAttributes_603475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_603488.validator(path, query, header, formData, body)
  let scheme = call_603488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603488.url(scheme.get, call_603488.host, call_603488.base,
                         call_603488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603488, url, valid)

proc call*(call_603489: Call_GetGetSMSAttributes_603475;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603490 = newJObject()
  if attributes != nil:
    query_603490.add "attributes", attributes
  add(query_603490, "Action", newJString(Action))
  add(query_603490, "Version", newJString(Version))
  result = call_603489.call(nil, query_603490, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_603475(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_603476, base: "/",
    url: url_GetGetSMSAttributes_603477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_603524 = ref object of OpenApiRestCall_602466
proc url_PostGetSubscriptionAttributes_603526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetSubscriptionAttributes_603525(path: JsonNode; query: JsonNode;
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
  var valid_603527 = query.getOrDefault("Action")
  valid_603527 = validateParameter(valid_603527, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_603527 != nil:
    section.add "Action", valid_603527
  var valid_603528 = query.getOrDefault("Version")
  valid_603528 = validateParameter(valid_603528, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603528 != nil:
    section.add "Version", valid_603528
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
  var valid_603529 = header.getOrDefault("X-Amz-Date")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Date", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Security-Token")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Security-Token", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Content-Sha256", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Algorithm")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Algorithm", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Signature")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Signature", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-SignedHeaders", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Credential")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Credential", valid_603535
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_603536 = formData.getOrDefault("SubscriptionArn")
  valid_603536 = validateParameter(valid_603536, JString, required = true,
                                 default = nil)
  if valid_603536 != nil:
    section.add "SubscriptionArn", valid_603536
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603537: Call_PostGetSubscriptionAttributes_603524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_603537.validator(path, query, header, formData, body)
  let scheme = call_603537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603537.url(scheme.get, call_603537.host, call_603537.base,
                         call_603537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603537, url, valid)

proc call*(call_603538: Call_PostGetSubscriptionAttributes_603524;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Version: string (required)
  var query_603539 = newJObject()
  var formData_603540 = newJObject()
  add(query_603539, "Action", newJString(Action))
  add(formData_603540, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_603539, "Version", newJString(Version))
  result = call_603538.call(nil, query_603539, nil, formData_603540, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_603524(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_603525, base: "/",
    url: url_PostGetSubscriptionAttributes_603526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_603508 = ref object of OpenApiRestCall_602466
proc url_GetGetSubscriptionAttributes_603510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetSubscriptionAttributes_603509(path: JsonNode; query: JsonNode;
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
  var valid_603511 = query.getOrDefault("SubscriptionArn")
  valid_603511 = validateParameter(valid_603511, JString, required = true,
                                 default = nil)
  if valid_603511 != nil:
    section.add "SubscriptionArn", valid_603511
  var valid_603512 = query.getOrDefault("Action")
  valid_603512 = validateParameter(valid_603512, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_603512 != nil:
    section.add "Action", valid_603512
  var valid_603513 = query.getOrDefault("Version")
  valid_603513 = validateParameter(valid_603513, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603513 != nil:
    section.add "Version", valid_603513
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
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Security-Token")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Security-Token", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Content-Sha256", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Algorithm")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Algorithm", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Signature")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Signature", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-SignedHeaders", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Credential")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Credential", valid_603520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603521: Call_GetGetSubscriptionAttributes_603508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_603521.validator(path, query, header, formData, body)
  let scheme = call_603521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603521.url(scheme.get, call_603521.host, call_603521.base,
                         call_603521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603521, url, valid)

proc call*(call_603522: Call_GetGetSubscriptionAttributes_603508;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603523 = newJObject()
  add(query_603523, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_603523, "Action", newJString(Action))
  add(query_603523, "Version", newJString(Version))
  result = call_603522.call(nil, query_603523, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_603508(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_603509, base: "/",
    url: url_GetGetSubscriptionAttributes_603510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_603557 = ref object of OpenApiRestCall_602466
proc url_PostGetTopicAttributes_603559(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetTopicAttributes_603558(path: JsonNode; query: JsonNode;
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
  var valid_603560 = query.getOrDefault("Action")
  valid_603560 = validateParameter(valid_603560, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_603560 != nil:
    section.add "Action", valid_603560
  var valid_603561 = query.getOrDefault("Version")
  valid_603561 = validateParameter(valid_603561, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603561 != nil:
    section.add "Version", valid_603561
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
  var valid_603562 = header.getOrDefault("X-Amz-Date")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Date", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Security-Token")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Security-Token", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Content-Sha256", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Algorithm")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Algorithm", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Signature")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Signature", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-SignedHeaders", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Credential")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Credential", valid_603568
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603569 = formData.getOrDefault("TopicArn")
  valid_603569 = validateParameter(valid_603569, JString, required = true,
                                 default = nil)
  if valid_603569 != nil:
    section.add "TopicArn", valid_603569
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603570: Call_PostGetTopicAttributes_603557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_603570.validator(path, query, header, formData, body)
  let scheme = call_603570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603570.url(scheme.get, call_603570.host, call_603570.base,
                         call_603570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603570, url, valid)

proc call*(call_603571: Call_PostGetTopicAttributes_603557; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603572 = newJObject()
  var formData_603573 = newJObject()
  add(formData_603573, "TopicArn", newJString(TopicArn))
  add(query_603572, "Action", newJString(Action))
  add(query_603572, "Version", newJString(Version))
  result = call_603571.call(nil, query_603572, nil, formData_603573, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_603557(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_603558, base: "/",
    url: url_PostGetTopicAttributes_603559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_603541 = ref object of OpenApiRestCall_602466
proc url_GetGetTopicAttributes_603543(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetTopicAttributes_603542(path: JsonNode; query: JsonNode;
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
  var valid_603544 = query.getOrDefault("Action")
  valid_603544 = validateParameter(valid_603544, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_603544 != nil:
    section.add "Action", valid_603544
  var valid_603545 = query.getOrDefault("TopicArn")
  valid_603545 = validateParameter(valid_603545, JString, required = true,
                                 default = nil)
  if valid_603545 != nil:
    section.add "TopicArn", valid_603545
  var valid_603546 = query.getOrDefault("Version")
  valid_603546 = validateParameter(valid_603546, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603546 != nil:
    section.add "Version", valid_603546
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
  var valid_603547 = header.getOrDefault("X-Amz-Date")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Date", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Security-Token")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Security-Token", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Content-Sha256", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Algorithm")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Algorithm", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Signature")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Signature", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-SignedHeaders", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Credential")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Credential", valid_603553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603554: Call_GetGetTopicAttributes_603541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_603554.validator(path, query, header, formData, body)
  let scheme = call_603554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603554.url(scheme.get, call_603554.host, call_603554.base,
                         call_603554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603554, url, valid)

proc call*(call_603555: Call_GetGetTopicAttributes_603541; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: string (required)
  var query_603556 = newJObject()
  add(query_603556, "Action", newJString(Action))
  add(query_603556, "TopicArn", newJString(TopicArn))
  add(query_603556, "Version", newJString(Version))
  result = call_603555.call(nil, query_603556, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_603541(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_603542, base: "/",
    url: url_GetGetTopicAttributes_603543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_603591 = ref object of OpenApiRestCall_602466
proc url_PostListEndpointsByPlatformApplication_603593(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListEndpointsByPlatformApplication_603592(path: JsonNode;
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
  var valid_603594 = query.getOrDefault("Action")
  valid_603594 = validateParameter(valid_603594, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_603594 != nil:
    section.add "Action", valid_603594
  var valid_603595 = query.getOrDefault("Version")
  valid_603595 = validateParameter(valid_603595, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603595 != nil:
    section.add "Version", valid_603595
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
  var valid_603596 = header.getOrDefault("X-Amz-Date")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Date", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Security-Token")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Security-Token", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Content-Sha256", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Algorithm")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Algorithm", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Signature")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Signature", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-SignedHeaders", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Credential")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Credential", valid_603602
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_603603 = formData.getOrDefault("NextToken")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "NextToken", valid_603603
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_603604 = formData.getOrDefault("PlatformApplicationArn")
  valid_603604 = validateParameter(valid_603604, JString, required = true,
                                 default = nil)
  if valid_603604 != nil:
    section.add "PlatformApplicationArn", valid_603604
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603605: Call_PostListEndpointsByPlatformApplication_603591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603605.validator(path, query, header, formData, body)
  let scheme = call_603605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603605.url(scheme.get, call_603605.host, call_603605.base,
                         call_603605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603605, url, valid)

proc call*(call_603606: Call_PostListEndpointsByPlatformApplication_603591;
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
  var query_603607 = newJObject()
  var formData_603608 = newJObject()
  add(formData_603608, "NextToken", newJString(NextToken))
  add(query_603607, "Action", newJString(Action))
  add(formData_603608, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_603607, "Version", newJString(Version))
  result = call_603606.call(nil, query_603607, nil, formData_603608, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_603591(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_603592, base: "/",
    url: url_PostListEndpointsByPlatformApplication_603593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_603574 = ref object of OpenApiRestCall_602466
proc url_GetListEndpointsByPlatformApplication_603576(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListEndpointsByPlatformApplication_603575(path: JsonNode;
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
  var valid_603577 = query.getOrDefault("NextToken")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "NextToken", valid_603577
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603578 = query.getOrDefault("Action")
  valid_603578 = validateParameter(valid_603578, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_603578 != nil:
    section.add "Action", valid_603578
  var valid_603579 = query.getOrDefault("Version")
  valid_603579 = validateParameter(valid_603579, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603579 != nil:
    section.add "Version", valid_603579
  var valid_603580 = query.getOrDefault("PlatformApplicationArn")
  valid_603580 = validateParameter(valid_603580, JString, required = true,
                                 default = nil)
  if valid_603580 != nil:
    section.add "PlatformApplicationArn", valid_603580
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
  var valid_603581 = header.getOrDefault("X-Amz-Date")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Date", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Security-Token")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Security-Token", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Content-Sha256", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Algorithm")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Algorithm", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Signature")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Signature", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-SignedHeaders", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Credential")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Credential", valid_603587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603588: Call_GetListEndpointsByPlatformApplication_603574;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603588.validator(path, query, header, formData, body)
  let scheme = call_603588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603588.url(scheme.get, call_603588.host, call_603588.base,
                         call_603588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603588, url, valid)

proc call*(call_603589: Call_GetListEndpointsByPlatformApplication_603574;
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
  var query_603590 = newJObject()
  add(query_603590, "NextToken", newJString(NextToken))
  add(query_603590, "Action", newJString(Action))
  add(query_603590, "Version", newJString(Version))
  add(query_603590, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603589.call(nil, query_603590, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_603574(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_603575, base: "/",
    url: url_GetListEndpointsByPlatformApplication_603576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_603625 = ref object of OpenApiRestCall_602466
proc url_PostListPhoneNumbersOptedOut_603627(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPhoneNumbersOptedOut_603626(path: JsonNode; query: JsonNode;
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
  var valid_603628 = query.getOrDefault("Action")
  valid_603628 = validateParameter(valid_603628, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_603628 != nil:
    section.add "Action", valid_603628
  var valid_603629 = query.getOrDefault("Version")
  valid_603629 = validateParameter(valid_603629, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603629 != nil:
    section.add "Version", valid_603629
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
  var valid_603630 = header.getOrDefault("X-Amz-Date")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Date", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Security-Token")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Security-Token", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Content-Sha256", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Algorithm")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Algorithm", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Signature")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Signature", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-SignedHeaders", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Credential")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Credential", valid_603636
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_603637 = formData.getOrDefault("nextToken")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "nextToken", valid_603637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603638: Call_PostListPhoneNumbersOptedOut_603625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_603638.validator(path, query, header, formData, body)
  let scheme = call_603638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603638.url(scheme.get, call_603638.host, call_603638.base,
                         call_603638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603638, url, valid)

proc call*(call_603639: Call_PostListPhoneNumbersOptedOut_603625;
          Action: string = "ListPhoneNumbersOptedOut"; nextToken: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   Action: string (required)
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Version: string (required)
  var query_603640 = newJObject()
  var formData_603641 = newJObject()
  add(query_603640, "Action", newJString(Action))
  add(formData_603641, "nextToken", newJString(nextToken))
  add(query_603640, "Version", newJString(Version))
  result = call_603639.call(nil, query_603640, nil, formData_603641, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_603625(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_603626, base: "/",
    url: url_PostListPhoneNumbersOptedOut_603627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_603609 = ref object of OpenApiRestCall_602466
proc url_GetListPhoneNumbersOptedOut_603611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPhoneNumbersOptedOut_603610(path: JsonNode; query: JsonNode;
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
  var valid_603612 = query.getOrDefault("nextToken")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "nextToken", valid_603612
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603613 = query.getOrDefault("Action")
  valid_603613 = validateParameter(valid_603613, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_603613 != nil:
    section.add "Action", valid_603613
  var valid_603614 = query.getOrDefault("Version")
  valid_603614 = validateParameter(valid_603614, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603614 != nil:
    section.add "Version", valid_603614
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
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Security-Token")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Security-Token", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Content-Sha256", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Algorithm")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Algorithm", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Signature")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Signature", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-SignedHeaders", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Credential")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Credential", valid_603621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603622: Call_GetListPhoneNumbersOptedOut_603609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_603622.validator(path, query, header, formData, body)
  let scheme = call_603622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603622.url(scheme.get, call_603622.host, call_603622.base,
                         call_603622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603622, url, valid)

proc call*(call_603623: Call_GetListPhoneNumbersOptedOut_603609;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603624 = newJObject()
  add(query_603624, "nextToken", newJString(nextToken))
  add(query_603624, "Action", newJString(Action))
  add(query_603624, "Version", newJString(Version))
  result = call_603623.call(nil, query_603624, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_603609(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_603610, base: "/",
    url: url_GetListPhoneNumbersOptedOut_603611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_603658 = ref object of OpenApiRestCall_602466
proc url_PostListPlatformApplications_603660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPlatformApplications_603659(path: JsonNode; query: JsonNode;
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
  var valid_603661 = query.getOrDefault("Action")
  valid_603661 = validateParameter(valid_603661, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_603661 != nil:
    section.add "Action", valid_603661
  var valid_603662 = query.getOrDefault("Version")
  valid_603662 = validateParameter(valid_603662, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603662 != nil:
    section.add "Version", valid_603662
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
  var valid_603663 = header.getOrDefault("X-Amz-Date")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Date", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Security-Token")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Security-Token", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Content-Sha256", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-Algorithm")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Algorithm", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Signature")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Signature", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-SignedHeaders", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Credential")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Credential", valid_603669
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_603670 = formData.getOrDefault("NextToken")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "NextToken", valid_603670
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603671: Call_PostListPlatformApplications_603658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_603671.validator(path, query, header, formData, body)
  let scheme = call_603671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603671.url(scheme.get, call_603671.host, call_603671.base,
                         call_603671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603671, url, valid)

proc call*(call_603672: Call_PostListPlatformApplications_603658;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603673 = newJObject()
  var formData_603674 = newJObject()
  add(formData_603674, "NextToken", newJString(NextToken))
  add(query_603673, "Action", newJString(Action))
  add(query_603673, "Version", newJString(Version))
  result = call_603672.call(nil, query_603673, nil, formData_603674, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_603658(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_603659, base: "/",
    url: url_PostListPlatformApplications_603660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_603642 = ref object of OpenApiRestCall_602466
proc url_GetListPlatformApplications_603644(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPlatformApplications_603643(path: JsonNode; query: JsonNode;
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
  var valid_603645 = query.getOrDefault("NextToken")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "NextToken", valid_603645
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603646 = query.getOrDefault("Action")
  valid_603646 = validateParameter(valid_603646, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_603646 != nil:
    section.add "Action", valid_603646
  var valid_603647 = query.getOrDefault("Version")
  valid_603647 = validateParameter(valid_603647, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603647 != nil:
    section.add "Version", valid_603647
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
  var valid_603648 = header.getOrDefault("X-Amz-Date")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Date", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Security-Token")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Security-Token", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Content-Sha256", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Algorithm")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Algorithm", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Signature")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Signature", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-SignedHeaders", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Credential")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Credential", valid_603654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603655: Call_GetListPlatformApplications_603642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_603655.validator(path, query, header, formData, body)
  let scheme = call_603655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603655.url(scheme.get, call_603655.host, call_603655.base,
                         call_603655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603655, url, valid)

proc call*(call_603656: Call_GetListPlatformApplications_603642;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603657 = newJObject()
  add(query_603657, "NextToken", newJString(NextToken))
  add(query_603657, "Action", newJString(Action))
  add(query_603657, "Version", newJString(Version))
  result = call_603656.call(nil, query_603657, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_603642(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_603643, base: "/",
    url: url_GetListPlatformApplications_603644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_603691 = ref object of OpenApiRestCall_602466
proc url_PostListSubscriptions_603693(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListSubscriptions_603692(path: JsonNode; query: JsonNode;
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
  var valid_603694 = query.getOrDefault("Action")
  valid_603694 = validateParameter(valid_603694, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_603694 != nil:
    section.add "Action", valid_603694
  var valid_603695 = query.getOrDefault("Version")
  valid_603695 = validateParameter(valid_603695, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603695 != nil:
    section.add "Version", valid_603695
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
  var valid_603696 = header.getOrDefault("X-Amz-Date")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Date", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Security-Token")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Security-Token", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Content-Sha256", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Algorithm")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Algorithm", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Signature")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Signature", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-SignedHeaders", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Credential")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Credential", valid_603702
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_603703 = formData.getOrDefault("NextToken")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "NextToken", valid_603703
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603704: Call_PostListSubscriptions_603691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603704.validator(path, query, header, formData, body)
  let scheme = call_603704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603704.url(scheme.get, call_603704.host, call_603704.base,
                         call_603704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603704, url, valid)

proc call*(call_603705: Call_PostListSubscriptions_603691; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603706 = newJObject()
  var formData_603707 = newJObject()
  add(formData_603707, "NextToken", newJString(NextToken))
  add(query_603706, "Action", newJString(Action))
  add(query_603706, "Version", newJString(Version))
  result = call_603705.call(nil, query_603706, nil, formData_603707, nil)

var postListSubscriptions* = Call_PostListSubscriptions_603691(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_603692, base: "/",
    url: url_PostListSubscriptions_603693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_603675 = ref object of OpenApiRestCall_602466
proc url_GetListSubscriptions_603677(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListSubscriptions_603676(path: JsonNode; query: JsonNode;
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
  var valid_603678 = query.getOrDefault("NextToken")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "NextToken", valid_603678
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603679 = query.getOrDefault("Action")
  valid_603679 = validateParameter(valid_603679, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_603679 != nil:
    section.add "Action", valid_603679
  var valid_603680 = query.getOrDefault("Version")
  valid_603680 = validateParameter(valid_603680, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603680 != nil:
    section.add "Version", valid_603680
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
  var valid_603681 = header.getOrDefault("X-Amz-Date")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-Date", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Security-Token")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Security-Token", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Content-Sha256", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Algorithm")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Algorithm", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Signature")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Signature", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-SignedHeaders", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Credential")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Credential", valid_603687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603688: Call_GetListSubscriptions_603675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603688.validator(path, query, header, formData, body)
  let scheme = call_603688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603688.url(scheme.get, call_603688.host, call_603688.base,
                         call_603688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603688, url, valid)

proc call*(call_603689: Call_GetListSubscriptions_603675; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603690 = newJObject()
  add(query_603690, "NextToken", newJString(NextToken))
  add(query_603690, "Action", newJString(Action))
  add(query_603690, "Version", newJString(Version))
  result = call_603689.call(nil, query_603690, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_603675(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_603676, base: "/",
    url: url_GetListSubscriptions_603677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_603725 = ref object of OpenApiRestCall_602466
proc url_PostListSubscriptionsByTopic_603727(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListSubscriptionsByTopic_603726(path: JsonNode; query: JsonNode;
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
  var valid_603728 = query.getOrDefault("Action")
  valid_603728 = validateParameter(valid_603728, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_603728 != nil:
    section.add "Action", valid_603728
  var valid_603729 = query.getOrDefault("Version")
  valid_603729 = validateParameter(valid_603729, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603729 != nil:
    section.add "Version", valid_603729
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
  var valid_603730 = header.getOrDefault("X-Amz-Date")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Date", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Security-Token")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Security-Token", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Content-Sha256", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Algorithm")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Algorithm", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Signature")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Signature", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-SignedHeaders", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Credential")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Credential", valid_603736
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_603737 = formData.getOrDefault("NextToken")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "NextToken", valid_603737
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603738 = formData.getOrDefault("TopicArn")
  valid_603738 = validateParameter(valid_603738, JString, required = true,
                                 default = nil)
  if valid_603738 != nil:
    section.add "TopicArn", valid_603738
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603739: Call_PostListSubscriptionsByTopic_603725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603739.validator(path, query, header, formData, body)
  let scheme = call_603739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603739.url(scheme.get, call_603739.host, call_603739.base,
                         call_603739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603739, url, valid)

proc call*(call_603740: Call_PostListSubscriptionsByTopic_603725; TopicArn: string;
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
  var query_603741 = newJObject()
  var formData_603742 = newJObject()
  add(formData_603742, "NextToken", newJString(NextToken))
  add(formData_603742, "TopicArn", newJString(TopicArn))
  add(query_603741, "Action", newJString(Action))
  add(query_603741, "Version", newJString(Version))
  result = call_603740.call(nil, query_603741, nil, formData_603742, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_603725(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_603726, base: "/",
    url: url_PostListSubscriptionsByTopic_603727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_603708 = ref object of OpenApiRestCall_602466
proc url_GetListSubscriptionsByTopic_603710(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListSubscriptionsByTopic_603709(path: JsonNode; query: JsonNode;
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
  var valid_603711 = query.getOrDefault("NextToken")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "NextToken", valid_603711
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603712 = query.getOrDefault("Action")
  valid_603712 = validateParameter(valid_603712, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_603712 != nil:
    section.add "Action", valid_603712
  var valid_603713 = query.getOrDefault("TopicArn")
  valid_603713 = validateParameter(valid_603713, JString, required = true,
                                 default = nil)
  if valid_603713 != nil:
    section.add "TopicArn", valid_603713
  var valid_603714 = query.getOrDefault("Version")
  valid_603714 = validateParameter(valid_603714, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603714 != nil:
    section.add "Version", valid_603714
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
  var valid_603715 = header.getOrDefault("X-Amz-Date")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Date", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Security-Token")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Security-Token", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Content-Sha256", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Algorithm")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Algorithm", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Signature")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Signature", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-SignedHeaders", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Credential")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Credential", valid_603721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603722: Call_GetListSubscriptionsByTopic_603708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603722.validator(path, query, header, formData, body)
  let scheme = call_603722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603722.url(scheme.get, call_603722.host, call_603722.base,
                         call_603722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603722, url, valid)

proc call*(call_603723: Call_GetListSubscriptionsByTopic_603708; TopicArn: string;
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
  var query_603724 = newJObject()
  add(query_603724, "NextToken", newJString(NextToken))
  add(query_603724, "Action", newJString(Action))
  add(query_603724, "TopicArn", newJString(TopicArn))
  add(query_603724, "Version", newJString(Version))
  result = call_603723.call(nil, query_603724, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_603708(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_603709, base: "/",
    url: url_GetListSubscriptionsByTopic_603710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_603759 = ref object of OpenApiRestCall_602466
proc url_PostListTagsForResource_603761(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_603760(path: JsonNode; query: JsonNode;
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
  var valid_603762 = query.getOrDefault("Action")
  valid_603762 = validateParameter(valid_603762, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603762 != nil:
    section.add "Action", valid_603762
  var valid_603763 = query.getOrDefault("Version")
  valid_603763 = validateParameter(valid_603763, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603763 != nil:
    section.add "Version", valid_603763
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
  var valid_603764 = header.getOrDefault("X-Amz-Date")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Date", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Security-Token")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Security-Token", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Content-Sha256", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Algorithm")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Algorithm", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Signature")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Signature", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-SignedHeaders", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Credential")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Credential", valid_603770
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_603771 = formData.getOrDefault("ResourceArn")
  valid_603771 = validateParameter(valid_603771, JString, required = true,
                                 default = nil)
  if valid_603771 != nil:
    section.add "ResourceArn", valid_603771
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603772: Call_PostListTagsForResource_603759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_603772.validator(path, query, header, formData, body)
  let scheme = call_603772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603772.url(scheme.get, call_603772.host, call_603772.base,
                         call_603772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603772, url, valid)

proc call*(call_603773: Call_PostListTagsForResource_603759; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Version: string (required)
  var query_603774 = newJObject()
  var formData_603775 = newJObject()
  add(query_603774, "Action", newJString(Action))
  add(formData_603775, "ResourceArn", newJString(ResourceArn))
  add(query_603774, "Version", newJString(Version))
  result = call_603773.call(nil, query_603774, nil, formData_603775, nil)

var postListTagsForResource* = Call_PostListTagsForResource_603759(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_603760, base: "/",
    url: url_PostListTagsForResource_603761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_603743 = ref object of OpenApiRestCall_602466
proc url_GetListTagsForResource_603745(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_603744(path: JsonNode; query: JsonNode;
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
  var valid_603746 = query.getOrDefault("ResourceArn")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = nil)
  if valid_603746 != nil:
    section.add "ResourceArn", valid_603746
  var valid_603747 = query.getOrDefault("Action")
  valid_603747 = validateParameter(valid_603747, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603747 != nil:
    section.add "Action", valid_603747
  var valid_603748 = query.getOrDefault("Version")
  valid_603748 = validateParameter(valid_603748, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603748 != nil:
    section.add "Version", valid_603748
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
  var valid_603749 = header.getOrDefault("X-Amz-Date")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Date", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Security-Token")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Security-Token", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Content-Sha256", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Algorithm")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Algorithm", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Signature")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Signature", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-SignedHeaders", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Credential")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Credential", valid_603755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603756: Call_GetListTagsForResource_603743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_603756.validator(path, query, header, formData, body)
  let scheme = call_603756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603756.url(scheme.get, call_603756.host, call_603756.base,
                         call_603756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603756, url, valid)

proc call*(call_603757: Call_GetListTagsForResource_603743; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603758 = newJObject()
  add(query_603758, "ResourceArn", newJString(ResourceArn))
  add(query_603758, "Action", newJString(Action))
  add(query_603758, "Version", newJString(Version))
  result = call_603757.call(nil, query_603758, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_603743(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_603744, base: "/",
    url: url_GetListTagsForResource_603745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_603792 = ref object of OpenApiRestCall_602466
proc url_PostListTopics_603794(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTopics_603793(path: JsonNode; query: JsonNode;
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
  var valid_603795 = query.getOrDefault("Action")
  valid_603795 = validateParameter(valid_603795, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_603795 != nil:
    section.add "Action", valid_603795
  var valid_603796 = query.getOrDefault("Version")
  valid_603796 = validateParameter(valid_603796, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603796 != nil:
    section.add "Version", valid_603796
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
  var valid_603797 = header.getOrDefault("X-Amz-Date")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Date", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Security-Token")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Security-Token", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Content-Sha256", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Algorithm")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Algorithm", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Signature")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Signature", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-SignedHeaders", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Credential")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Credential", valid_603803
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_603804 = formData.getOrDefault("NextToken")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "NextToken", valid_603804
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603805: Call_PostListTopics_603792; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603805.validator(path, query, header, formData, body)
  let scheme = call_603805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603805.url(scheme.get, call_603805.host, call_603805.base,
                         call_603805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603805, url, valid)

proc call*(call_603806: Call_PostListTopics_603792; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603807 = newJObject()
  var formData_603808 = newJObject()
  add(formData_603808, "NextToken", newJString(NextToken))
  add(query_603807, "Action", newJString(Action))
  add(query_603807, "Version", newJString(Version))
  result = call_603806.call(nil, query_603807, nil, formData_603808, nil)

var postListTopics* = Call_PostListTopics_603792(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_603793,
    base: "/", url: url_PostListTopics_603794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_603776 = ref object of OpenApiRestCall_602466
proc url_GetListTopics_603778(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTopics_603777(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603779 = query.getOrDefault("NextToken")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "NextToken", valid_603779
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603780 = query.getOrDefault("Action")
  valid_603780 = validateParameter(valid_603780, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_603780 != nil:
    section.add "Action", valid_603780
  var valid_603781 = query.getOrDefault("Version")
  valid_603781 = validateParameter(valid_603781, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603781 != nil:
    section.add "Version", valid_603781
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
  var valid_603782 = header.getOrDefault("X-Amz-Date")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Date", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Security-Token")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Security-Token", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Content-Sha256", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Algorithm")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Algorithm", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Signature")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Signature", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-SignedHeaders", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Credential")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Credential", valid_603788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603789: Call_GetListTopics_603776; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603789.validator(path, query, header, formData, body)
  let scheme = call_603789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603789.url(scheme.get, call_603789.host, call_603789.base,
                         call_603789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603789, url, valid)

proc call*(call_603790: Call_GetListTopics_603776; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603791 = newJObject()
  add(query_603791, "NextToken", newJString(NextToken))
  add(query_603791, "Action", newJString(Action))
  add(query_603791, "Version", newJString(Version))
  result = call_603790.call(nil, query_603791, nil, nil, nil)

var getListTopics* = Call_GetListTopics_603776(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_603777,
    base: "/", url: url_GetListTopics_603778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_603825 = ref object of OpenApiRestCall_602466
proc url_PostOptInPhoneNumber_603827(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostOptInPhoneNumber_603826(path: JsonNode; query: JsonNode;
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
  var valid_603828 = query.getOrDefault("Action")
  valid_603828 = validateParameter(valid_603828, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_603828 != nil:
    section.add "Action", valid_603828
  var valid_603829 = query.getOrDefault("Version")
  valid_603829 = validateParameter(valid_603829, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603829 != nil:
    section.add "Version", valid_603829
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
  var valid_603830 = header.getOrDefault("X-Amz-Date")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Date", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-Security-Token")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Security-Token", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Content-Sha256", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-Algorithm")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Algorithm", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Signature")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Signature", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-SignedHeaders", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Credential")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Credential", valid_603836
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_603837 = formData.getOrDefault("phoneNumber")
  valid_603837 = validateParameter(valid_603837, JString, required = true,
                                 default = nil)
  if valid_603837 != nil:
    section.add "phoneNumber", valid_603837
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603838: Call_PostOptInPhoneNumber_603825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_603838.validator(path, query, header, formData, body)
  let scheme = call_603838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603838.url(scheme.get, call_603838.host, call_603838.base,
                         call_603838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603838, url, valid)

proc call*(call_603839: Call_PostOptInPhoneNumber_603825; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Version: string (required)
  var query_603840 = newJObject()
  var formData_603841 = newJObject()
  add(query_603840, "Action", newJString(Action))
  add(formData_603841, "phoneNumber", newJString(phoneNumber))
  add(query_603840, "Version", newJString(Version))
  result = call_603839.call(nil, query_603840, nil, formData_603841, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_603825(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_603826, base: "/",
    url: url_PostOptInPhoneNumber_603827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_603809 = ref object of OpenApiRestCall_602466
proc url_GetOptInPhoneNumber_603811(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOptInPhoneNumber_603810(path: JsonNode; query: JsonNode;
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
  var valid_603812 = query.getOrDefault("phoneNumber")
  valid_603812 = validateParameter(valid_603812, JString, required = true,
                                 default = nil)
  if valid_603812 != nil:
    section.add "phoneNumber", valid_603812
  var valid_603813 = query.getOrDefault("Action")
  valid_603813 = validateParameter(valid_603813, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_603813 != nil:
    section.add "Action", valid_603813
  var valid_603814 = query.getOrDefault("Version")
  valid_603814 = validateParameter(valid_603814, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603814 != nil:
    section.add "Version", valid_603814
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
  var valid_603815 = header.getOrDefault("X-Amz-Date")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Date", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Security-Token")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Security-Token", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Content-Sha256", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Algorithm")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Algorithm", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Signature")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Signature", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-SignedHeaders", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Credential")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Credential", valid_603821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603822: Call_GetOptInPhoneNumber_603809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_603822.validator(path, query, header, formData, body)
  let scheme = call_603822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603822.url(scheme.get, call_603822.host, call_603822.base,
                         call_603822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603822, url, valid)

proc call*(call_603823: Call_GetOptInPhoneNumber_603809; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603824 = newJObject()
  add(query_603824, "phoneNumber", newJString(phoneNumber))
  add(query_603824, "Action", newJString(Action))
  add(query_603824, "Version", newJString(Version))
  result = call_603823.call(nil, query_603824, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_603809(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_603810, base: "/",
    url: url_GetOptInPhoneNumber_603811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_603869 = ref object of OpenApiRestCall_602466
proc url_PostPublish_603871(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPublish_603870(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603872 = query.getOrDefault("Action")
  valid_603872 = validateParameter(valid_603872, JString, required = true,
                                 default = newJString("Publish"))
  if valid_603872 != nil:
    section.add "Action", valid_603872
  var valid_603873 = query.getOrDefault("Version")
  valid_603873 = validateParameter(valid_603873, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603873 != nil:
    section.add "Version", valid_603873
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
  var valid_603874 = header.getOrDefault("X-Amz-Date")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Date", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Security-Token")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Security-Token", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Content-Sha256", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Algorithm")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Algorithm", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Signature")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Signature", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-SignedHeaders", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Credential")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Credential", valid_603880
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
  var valid_603881 = formData.getOrDefault("TopicArn")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "TopicArn", valid_603881
  var valid_603882 = formData.getOrDefault("Subject")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "Subject", valid_603882
  var valid_603883 = formData.getOrDefault("MessageAttributes.1.key")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "MessageAttributes.1.key", valid_603883
  var valid_603884 = formData.getOrDefault("TargetArn")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "TargetArn", valid_603884
  var valid_603885 = formData.getOrDefault("PhoneNumber")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "PhoneNumber", valid_603885
  var valid_603886 = formData.getOrDefault("MessageAttributes.0.value")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "MessageAttributes.0.value", valid_603886
  var valid_603887 = formData.getOrDefault("MessageAttributes.1.value")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "MessageAttributes.1.value", valid_603887
  var valid_603888 = formData.getOrDefault("MessageAttributes.0.key")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "MessageAttributes.0.key", valid_603888
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_603889 = formData.getOrDefault("Message")
  valid_603889 = validateParameter(valid_603889, JString, required = true,
                                 default = nil)
  if valid_603889 != nil:
    section.add "Message", valid_603889
  var valid_603890 = formData.getOrDefault("MessageStructure")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "MessageStructure", valid_603890
  var valid_603891 = formData.getOrDefault("MessageAttributes.2.key")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "MessageAttributes.2.key", valid_603891
  var valid_603892 = formData.getOrDefault("MessageAttributes.2.value")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "MessageAttributes.2.value", valid_603892
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603893: Call_PostPublish_603869; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_603893.validator(path, query, header, formData, body)
  let scheme = call_603893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603893.url(scheme.get, call_603893.host, call_603893.base,
                         call_603893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603893, url, valid)

proc call*(call_603894: Call_PostPublish_603869; Message: string;
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
  var query_603895 = newJObject()
  var formData_603896 = newJObject()
  add(formData_603896, "TopicArn", newJString(TopicArn))
  add(formData_603896, "Subject", newJString(Subject))
  add(formData_603896, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_603896, "TargetArn", newJString(TargetArn))
  add(formData_603896, "PhoneNumber", newJString(PhoneNumber))
  add(formData_603896, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_603896, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_603896, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_603896, "Message", newJString(Message))
  add(query_603895, "Action", newJString(Action))
  add(formData_603896, "MessageStructure", newJString(MessageStructure))
  add(formData_603896, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(query_603895, "Version", newJString(Version))
  add(formData_603896, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  result = call_603894.call(nil, query_603895, nil, formData_603896, nil)

var postPublish* = Call_PostPublish_603869(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_603870,
                                        base: "/", url: url_PostPublish_603871,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_603842 = ref object of OpenApiRestCall_602466
proc url_GetPublish_603844(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPublish_603843(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603845 = query.getOrDefault("MessageAttributes.0.value")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "MessageAttributes.0.value", valid_603845
  var valid_603846 = query.getOrDefault("MessageAttributes.0.key")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "MessageAttributes.0.key", valid_603846
  var valid_603847 = query.getOrDefault("MessageAttributes.1.value")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "MessageAttributes.1.value", valid_603847
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_603848 = query.getOrDefault("Message")
  valid_603848 = validateParameter(valid_603848, JString, required = true,
                                 default = nil)
  if valid_603848 != nil:
    section.add "Message", valid_603848
  var valid_603849 = query.getOrDefault("Subject")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "Subject", valid_603849
  var valid_603850 = query.getOrDefault("Action")
  valid_603850 = validateParameter(valid_603850, JString, required = true,
                                 default = newJString("Publish"))
  if valid_603850 != nil:
    section.add "Action", valid_603850
  var valid_603851 = query.getOrDefault("MessageAttributes.2.value")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "MessageAttributes.2.value", valid_603851
  var valid_603852 = query.getOrDefault("MessageStructure")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "MessageStructure", valid_603852
  var valid_603853 = query.getOrDefault("TopicArn")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "TopicArn", valid_603853
  var valid_603854 = query.getOrDefault("PhoneNumber")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "PhoneNumber", valid_603854
  var valid_603855 = query.getOrDefault("MessageAttributes.1.key")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "MessageAttributes.1.key", valid_603855
  var valid_603856 = query.getOrDefault("MessageAttributes.2.key")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "MessageAttributes.2.key", valid_603856
  var valid_603857 = query.getOrDefault("TargetArn")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "TargetArn", valid_603857
  var valid_603858 = query.getOrDefault("Version")
  valid_603858 = validateParameter(valid_603858, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603858 != nil:
    section.add "Version", valid_603858
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
  var valid_603859 = header.getOrDefault("X-Amz-Date")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Date", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Security-Token")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Security-Token", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Content-Sha256", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Algorithm")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Algorithm", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Signature")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Signature", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-SignedHeaders", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Credential")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Credential", valid_603865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603866: Call_GetPublish_603842; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_603866.validator(path, query, header, formData, body)
  let scheme = call_603866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603866.url(scheme.get, call_603866.host, call_603866.base,
                         call_603866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603866, url, valid)

proc call*(call_603867: Call_GetPublish_603842; Message: string;
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
  var query_603868 = newJObject()
  add(query_603868, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_603868, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_603868, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_603868, "Message", newJString(Message))
  add(query_603868, "Subject", newJString(Subject))
  add(query_603868, "Action", newJString(Action))
  add(query_603868, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_603868, "MessageStructure", newJString(MessageStructure))
  add(query_603868, "TopicArn", newJString(TopicArn))
  add(query_603868, "PhoneNumber", newJString(PhoneNumber))
  add(query_603868, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_603868, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_603868, "TargetArn", newJString(TargetArn))
  add(query_603868, "Version", newJString(Version))
  result = call_603867.call(nil, query_603868, nil, nil, nil)

var getPublish* = Call_GetPublish_603842(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_603843,
                                      base: "/", url: url_GetPublish_603844,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_603914 = ref object of OpenApiRestCall_602466
proc url_PostRemovePermission_603916(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemovePermission_603915(path: JsonNode; query: JsonNode;
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
  var valid_603917 = query.getOrDefault("Action")
  valid_603917 = validateParameter(valid_603917, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_603917 != nil:
    section.add "Action", valid_603917
  var valid_603918 = query.getOrDefault("Version")
  valid_603918 = validateParameter(valid_603918, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603918 != nil:
    section.add "Version", valid_603918
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
  var valid_603919 = header.getOrDefault("X-Amz-Date")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Date", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Security-Token")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Security-Token", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Content-Sha256", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Algorithm")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Algorithm", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Signature")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Signature", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-SignedHeaders", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Credential")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Credential", valid_603925
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603926 = formData.getOrDefault("TopicArn")
  valid_603926 = validateParameter(valid_603926, JString, required = true,
                                 default = nil)
  if valid_603926 != nil:
    section.add "TopicArn", valid_603926
  var valid_603927 = formData.getOrDefault("Label")
  valid_603927 = validateParameter(valid_603927, JString, required = true,
                                 default = nil)
  if valid_603927 != nil:
    section.add "Label", valid_603927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603928: Call_PostRemovePermission_603914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_603928.validator(path, query, header, formData, body)
  let scheme = call_603928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603928.url(scheme.get, call_603928.host, call_603928.base,
                         call_603928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603928, url, valid)

proc call*(call_603929: Call_PostRemovePermission_603914; TopicArn: string;
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
  var query_603930 = newJObject()
  var formData_603931 = newJObject()
  add(formData_603931, "TopicArn", newJString(TopicArn))
  add(formData_603931, "Label", newJString(Label))
  add(query_603930, "Action", newJString(Action))
  add(query_603930, "Version", newJString(Version))
  result = call_603929.call(nil, query_603930, nil, formData_603931, nil)

var postRemovePermission* = Call_PostRemovePermission_603914(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_603915, base: "/",
    url: url_PostRemovePermission_603916, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_603897 = ref object of OpenApiRestCall_602466
proc url_GetRemovePermission_603899(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemovePermission_603898(path: JsonNode; query: JsonNode;
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
  var valid_603900 = query.getOrDefault("Action")
  valid_603900 = validateParameter(valid_603900, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_603900 != nil:
    section.add "Action", valid_603900
  var valid_603901 = query.getOrDefault("TopicArn")
  valid_603901 = validateParameter(valid_603901, JString, required = true,
                                 default = nil)
  if valid_603901 != nil:
    section.add "TopicArn", valid_603901
  var valid_603902 = query.getOrDefault("Version")
  valid_603902 = validateParameter(valid_603902, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603902 != nil:
    section.add "Version", valid_603902
  var valid_603903 = query.getOrDefault("Label")
  valid_603903 = validateParameter(valid_603903, JString, required = true,
                                 default = nil)
  if valid_603903 != nil:
    section.add "Label", valid_603903
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
  var valid_603904 = header.getOrDefault("X-Amz-Date")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Date", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-Security-Token")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Security-Token", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Content-Sha256", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Algorithm")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Algorithm", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Signature")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Signature", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-SignedHeaders", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Credential")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Credential", valid_603910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603911: Call_GetRemovePermission_603897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_603911.validator(path, query, header, formData, body)
  let scheme = call_603911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603911.url(scheme.get, call_603911.host, call_603911.base,
                         call_603911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603911, url, valid)

proc call*(call_603912: Call_GetRemovePermission_603897; TopicArn: string;
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
  var query_603913 = newJObject()
  add(query_603913, "Action", newJString(Action))
  add(query_603913, "TopicArn", newJString(TopicArn))
  add(query_603913, "Version", newJString(Version))
  add(query_603913, "Label", newJString(Label))
  result = call_603912.call(nil, query_603913, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_603897(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_603898, base: "/",
    url: url_GetRemovePermission_603899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_603954 = ref object of OpenApiRestCall_602466
proc url_PostSetEndpointAttributes_603956(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetEndpointAttributes_603955(path: JsonNode; query: JsonNode;
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
  var valid_603957 = query.getOrDefault("Action")
  valid_603957 = validateParameter(valid_603957, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_603957 != nil:
    section.add "Action", valid_603957
  var valid_603958 = query.getOrDefault("Version")
  valid_603958 = validateParameter(valid_603958, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603958 != nil:
    section.add "Version", valid_603958
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
  var valid_603959 = header.getOrDefault("X-Amz-Date")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Date", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Security-Token")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Security-Token", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-Content-Sha256", valid_603961
  var valid_603962 = header.getOrDefault("X-Amz-Algorithm")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "X-Amz-Algorithm", valid_603962
  var valid_603963 = header.getOrDefault("X-Amz-Signature")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "X-Amz-Signature", valid_603963
  var valid_603964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-SignedHeaders", valid_603964
  var valid_603965 = header.getOrDefault("X-Amz-Credential")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "X-Amz-Credential", valid_603965
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
  var valid_603966 = formData.getOrDefault("Attributes.0.value")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "Attributes.0.value", valid_603966
  var valid_603967 = formData.getOrDefault("Attributes.0.key")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "Attributes.0.key", valid_603967
  var valid_603968 = formData.getOrDefault("Attributes.1.key")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "Attributes.1.key", valid_603968
  var valid_603969 = formData.getOrDefault("Attributes.2.value")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "Attributes.2.value", valid_603969
  var valid_603970 = formData.getOrDefault("Attributes.2.key")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "Attributes.2.key", valid_603970
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_603971 = formData.getOrDefault("EndpointArn")
  valid_603971 = validateParameter(valid_603971, JString, required = true,
                                 default = nil)
  if valid_603971 != nil:
    section.add "EndpointArn", valid_603971
  var valid_603972 = formData.getOrDefault("Attributes.1.value")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "Attributes.1.value", valid_603972
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603973: Call_PostSetEndpointAttributes_603954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603973.validator(path, query, header, formData, body)
  let scheme = call_603973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603973.url(scheme.get, call_603973.host, call_603973.base,
                         call_603973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603973, url, valid)

proc call*(call_603974: Call_PostSetEndpointAttributes_603954; EndpointArn: string;
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
  var query_603975 = newJObject()
  var formData_603976 = newJObject()
  add(formData_603976, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603976, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_603976, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603975, "Action", newJString(Action))
  add(formData_603976, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603976, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_603976, "EndpointArn", newJString(EndpointArn))
  add(query_603975, "Version", newJString(Version))
  add(formData_603976, "Attributes.1.value", newJString(Attributes1Value))
  result = call_603974.call(nil, query_603975, nil, formData_603976, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_603954(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_603955, base: "/",
    url: url_PostSetEndpointAttributes_603956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_603932 = ref object of OpenApiRestCall_602466
proc url_GetSetEndpointAttributes_603934(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetEndpointAttributes_603933(path: JsonNode; query: JsonNode;
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
  var valid_603935 = query.getOrDefault("EndpointArn")
  valid_603935 = validateParameter(valid_603935, JString, required = true,
                                 default = nil)
  if valid_603935 != nil:
    section.add "EndpointArn", valid_603935
  var valid_603936 = query.getOrDefault("Attributes.2.key")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "Attributes.2.key", valid_603936
  var valid_603937 = query.getOrDefault("Attributes.1.value")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "Attributes.1.value", valid_603937
  var valid_603938 = query.getOrDefault("Attributes.0.value")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "Attributes.0.value", valid_603938
  var valid_603939 = query.getOrDefault("Action")
  valid_603939 = validateParameter(valid_603939, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_603939 != nil:
    section.add "Action", valid_603939
  var valid_603940 = query.getOrDefault("Attributes.1.key")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "Attributes.1.key", valid_603940
  var valid_603941 = query.getOrDefault("Attributes.2.value")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "Attributes.2.value", valid_603941
  var valid_603942 = query.getOrDefault("Attributes.0.key")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "Attributes.0.key", valid_603942
  var valid_603943 = query.getOrDefault("Version")
  valid_603943 = validateParameter(valid_603943, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603943 != nil:
    section.add "Version", valid_603943
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
  var valid_603944 = header.getOrDefault("X-Amz-Date")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Date", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Security-Token")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Security-Token", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Content-Sha256", valid_603946
  var valid_603947 = header.getOrDefault("X-Amz-Algorithm")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "X-Amz-Algorithm", valid_603947
  var valid_603948 = header.getOrDefault("X-Amz-Signature")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Signature", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-SignedHeaders", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Credential")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Credential", valid_603950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603951: Call_GetSetEndpointAttributes_603932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603951.validator(path, query, header, formData, body)
  let scheme = call_603951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603951.url(scheme.get, call_603951.host, call_603951.base,
                         call_603951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603951, url, valid)

proc call*(call_603952: Call_GetSetEndpointAttributes_603932; EndpointArn: string;
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
  var query_603953 = newJObject()
  add(query_603953, "EndpointArn", newJString(EndpointArn))
  add(query_603953, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603953, "Attributes.1.value", newJString(Attributes1Value))
  add(query_603953, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603953, "Action", newJString(Action))
  add(query_603953, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603953, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603953, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603953, "Version", newJString(Version))
  result = call_603952.call(nil, query_603953, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_603932(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_603933, base: "/",
    url: url_GetSetEndpointAttributes_603934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_603999 = ref object of OpenApiRestCall_602466
proc url_PostSetPlatformApplicationAttributes_604001(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetPlatformApplicationAttributes_604000(path: JsonNode;
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
  var valid_604002 = query.getOrDefault("Action")
  valid_604002 = validateParameter(valid_604002, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_604002 != nil:
    section.add "Action", valid_604002
  var valid_604003 = query.getOrDefault("Version")
  valid_604003 = validateParameter(valid_604003, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604003 != nil:
    section.add "Version", valid_604003
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
  var valid_604004 = header.getOrDefault("X-Amz-Date")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Date", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Security-Token")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Security-Token", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-Content-Sha256", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Algorithm")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Algorithm", valid_604007
  var valid_604008 = header.getOrDefault("X-Amz-Signature")
  valid_604008 = validateParameter(valid_604008, JString, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "X-Amz-Signature", valid_604008
  var valid_604009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-SignedHeaders", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-Credential")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-Credential", valid_604010
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
  var valid_604011 = formData.getOrDefault("Attributes.0.value")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "Attributes.0.value", valid_604011
  var valid_604012 = formData.getOrDefault("Attributes.0.key")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "Attributes.0.key", valid_604012
  var valid_604013 = formData.getOrDefault("Attributes.1.key")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "Attributes.1.key", valid_604013
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_604014 = formData.getOrDefault("PlatformApplicationArn")
  valid_604014 = validateParameter(valid_604014, JString, required = true,
                                 default = nil)
  if valid_604014 != nil:
    section.add "PlatformApplicationArn", valid_604014
  var valid_604015 = formData.getOrDefault("Attributes.2.value")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "Attributes.2.value", valid_604015
  var valid_604016 = formData.getOrDefault("Attributes.2.key")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "Attributes.2.key", valid_604016
  var valid_604017 = formData.getOrDefault("Attributes.1.value")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "Attributes.1.value", valid_604017
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604018: Call_PostSetPlatformApplicationAttributes_603999;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_604018.validator(path, query, header, formData, body)
  let scheme = call_604018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604018.url(scheme.get, call_604018.host, call_604018.base,
                         call_604018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604018, url, valid)

proc call*(call_604019: Call_PostSetPlatformApplicationAttributes_603999;
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
  var query_604020 = newJObject()
  var formData_604021 = newJObject()
  add(formData_604021, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_604021, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_604021, "Attributes.1.key", newJString(Attributes1Key))
  add(query_604020, "Action", newJString(Action))
  add(formData_604021, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_604021, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_604021, "Attributes.2.key", newJString(Attributes2Key))
  add(query_604020, "Version", newJString(Version))
  add(formData_604021, "Attributes.1.value", newJString(Attributes1Value))
  result = call_604019.call(nil, query_604020, nil, formData_604021, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_603999(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_604000, base: "/",
    url: url_PostSetPlatformApplicationAttributes_604001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_603977 = ref object of OpenApiRestCall_602466
proc url_GetSetPlatformApplicationAttributes_603979(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetPlatformApplicationAttributes_603978(path: JsonNode;
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
  var valid_603980 = query.getOrDefault("Attributes.2.key")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "Attributes.2.key", valid_603980
  var valid_603981 = query.getOrDefault("Attributes.1.value")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "Attributes.1.value", valid_603981
  var valid_603982 = query.getOrDefault("Attributes.0.value")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "Attributes.0.value", valid_603982
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603983 = query.getOrDefault("Action")
  valid_603983 = validateParameter(valid_603983, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_603983 != nil:
    section.add "Action", valid_603983
  var valid_603984 = query.getOrDefault("Attributes.1.key")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "Attributes.1.key", valid_603984
  var valid_603985 = query.getOrDefault("Attributes.2.value")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "Attributes.2.value", valid_603985
  var valid_603986 = query.getOrDefault("Attributes.0.key")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "Attributes.0.key", valid_603986
  var valid_603987 = query.getOrDefault("Version")
  valid_603987 = validateParameter(valid_603987, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603987 != nil:
    section.add "Version", valid_603987
  var valid_603988 = query.getOrDefault("PlatformApplicationArn")
  valid_603988 = validateParameter(valid_603988, JString, required = true,
                                 default = nil)
  if valid_603988 != nil:
    section.add "PlatformApplicationArn", valid_603988
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
  var valid_603989 = header.getOrDefault("X-Amz-Date")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Date", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-Security-Token")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Security-Token", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Content-Sha256", valid_603991
  var valid_603992 = header.getOrDefault("X-Amz-Algorithm")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Algorithm", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Signature")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Signature", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-SignedHeaders", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Credential")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Credential", valid_603995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603996: Call_GetSetPlatformApplicationAttributes_603977;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_603996.validator(path, query, header, formData, body)
  let scheme = call_603996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603996.url(scheme.get, call_603996.host, call_603996.base,
                         call_603996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603996, url, valid)

proc call*(call_603997: Call_GetSetPlatformApplicationAttributes_603977;
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
  var query_603998 = newJObject()
  add(query_603998, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603998, "Attributes.1.value", newJString(Attributes1Value))
  add(query_603998, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603998, "Action", newJString(Action))
  add(query_603998, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603998, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603998, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603998, "Version", newJString(Version))
  add(query_603998, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603997.call(nil, query_603998, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_603977(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_603978, base: "/",
    url: url_GetSetPlatformApplicationAttributes_603979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_604043 = ref object of OpenApiRestCall_602466
proc url_PostSetSMSAttributes_604045(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSMSAttributes_604044(path: JsonNode; query: JsonNode;
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
  var valid_604046 = query.getOrDefault("Action")
  valid_604046 = validateParameter(valid_604046, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_604046 != nil:
    section.add "Action", valid_604046
  var valid_604047 = query.getOrDefault("Version")
  valid_604047 = validateParameter(valid_604047, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604047 != nil:
    section.add "Version", valid_604047
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
  var valid_604048 = header.getOrDefault("X-Amz-Date")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-Date", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-Security-Token")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Security-Token", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Content-Sha256", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-Algorithm")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-Algorithm", valid_604051
  var valid_604052 = header.getOrDefault("X-Amz-Signature")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "X-Amz-Signature", valid_604052
  var valid_604053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "X-Amz-SignedHeaders", valid_604053
  var valid_604054 = header.getOrDefault("X-Amz-Credential")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-Credential", valid_604054
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.2.value: JString
  ##   attributes.2.key: JString
  ##   attributes.1.value: JString
  ##   attributes.1.key: JString
  ##   attributes.0.key: JString
  ##   attributes.0.value: JString
  section = newJObject()
  var valid_604055 = formData.getOrDefault("attributes.2.value")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "attributes.2.value", valid_604055
  var valid_604056 = formData.getOrDefault("attributes.2.key")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "attributes.2.key", valid_604056
  var valid_604057 = formData.getOrDefault("attributes.1.value")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "attributes.1.value", valid_604057
  var valid_604058 = formData.getOrDefault("attributes.1.key")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "attributes.1.key", valid_604058
  var valid_604059 = formData.getOrDefault("attributes.0.key")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "attributes.0.key", valid_604059
  var valid_604060 = formData.getOrDefault("attributes.0.value")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "attributes.0.value", valid_604060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604061: Call_PostSetSMSAttributes_604043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_604061.validator(path, query, header, formData, body)
  let scheme = call_604061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604061.url(scheme.get, call_604061.host, call_604061.base,
                         call_604061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604061, url, valid)

proc call*(call_604062: Call_PostSetSMSAttributes_604043;
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
  var query_604063 = newJObject()
  var formData_604064 = newJObject()
  add(formData_604064, "attributes.2.value", newJString(attributes2Value))
  add(formData_604064, "attributes.2.key", newJString(attributes2Key))
  add(query_604063, "Action", newJString(Action))
  add(formData_604064, "attributes.1.value", newJString(attributes1Value))
  add(formData_604064, "attributes.1.key", newJString(attributes1Key))
  add(formData_604064, "attributes.0.key", newJString(attributes0Key))
  add(query_604063, "Version", newJString(Version))
  add(formData_604064, "attributes.0.value", newJString(attributes0Value))
  result = call_604062.call(nil, query_604063, nil, formData_604064, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_604043(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_604044, base: "/",
    url: url_PostSetSMSAttributes_604045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_604022 = ref object of OpenApiRestCall_602466
proc url_GetSetSMSAttributes_604024(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSMSAttributes_604023(path: JsonNode; query: JsonNode;
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
  var valid_604025 = query.getOrDefault("attributes.2.key")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "attributes.2.key", valid_604025
  var valid_604026 = query.getOrDefault("attributes.1.key")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "attributes.1.key", valid_604026
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604027 = query.getOrDefault("Action")
  valid_604027 = validateParameter(valid_604027, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_604027 != nil:
    section.add "Action", valid_604027
  var valid_604028 = query.getOrDefault("attributes.1.value")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "attributes.1.value", valid_604028
  var valid_604029 = query.getOrDefault("attributes.0.value")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "attributes.0.value", valid_604029
  var valid_604030 = query.getOrDefault("attributes.2.value")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "attributes.2.value", valid_604030
  var valid_604031 = query.getOrDefault("attributes.0.key")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "attributes.0.key", valid_604031
  var valid_604032 = query.getOrDefault("Version")
  valid_604032 = validateParameter(valid_604032, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604032 != nil:
    section.add "Version", valid_604032
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
  var valid_604033 = header.getOrDefault("X-Amz-Date")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Date", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Security-Token")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Security-Token", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Content-Sha256", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-Algorithm")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Algorithm", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Signature")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Signature", valid_604037
  var valid_604038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-SignedHeaders", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Credential")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Credential", valid_604039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604040: Call_GetSetSMSAttributes_604022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_604040.validator(path, query, header, formData, body)
  let scheme = call_604040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604040.url(scheme.get, call_604040.host, call_604040.base,
                         call_604040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604040, url, valid)

proc call*(call_604041: Call_GetSetSMSAttributes_604022;
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
  var query_604042 = newJObject()
  add(query_604042, "attributes.2.key", newJString(attributes2Key))
  add(query_604042, "attributes.1.key", newJString(attributes1Key))
  add(query_604042, "Action", newJString(Action))
  add(query_604042, "attributes.1.value", newJString(attributes1Value))
  add(query_604042, "attributes.0.value", newJString(attributes0Value))
  add(query_604042, "attributes.2.value", newJString(attributes2Value))
  add(query_604042, "attributes.0.key", newJString(attributes0Key))
  add(query_604042, "Version", newJString(Version))
  result = call_604041.call(nil, query_604042, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_604022(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_604023, base: "/",
    url: url_GetSetSMSAttributes_604024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_604083 = ref object of OpenApiRestCall_602466
proc url_PostSetSubscriptionAttributes_604085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSubscriptionAttributes_604084(path: JsonNode; query: JsonNode;
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
  var valid_604086 = query.getOrDefault("Action")
  valid_604086 = validateParameter(valid_604086, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_604086 != nil:
    section.add "Action", valid_604086
  var valid_604087 = query.getOrDefault("Version")
  valid_604087 = validateParameter(valid_604087, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604087 != nil:
    section.add "Version", valid_604087
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
  var valid_604088 = header.getOrDefault("X-Amz-Date")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Date", valid_604088
  var valid_604089 = header.getOrDefault("X-Amz-Security-Token")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "X-Amz-Security-Token", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-Content-Sha256", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Algorithm")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Algorithm", valid_604091
  var valid_604092 = header.getOrDefault("X-Amz-Signature")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Signature", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-SignedHeaders", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Credential")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Credential", valid_604094
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
  var valid_604095 = formData.getOrDefault("AttributeName")
  valid_604095 = validateParameter(valid_604095, JString, required = true,
                                 default = nil)
  if valid_604095 != nil:
    section.add "AttributeName", valid_604095
  var valid_604096 = formData.getOrDefault("AttributeValue")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "AttributeValue", valid_604096
  var valid_604097 = formData.getOrDefault("SubscriptionArn")
  valid_604097 = validateParameter(valid_604097, JString, required = true,
                                 default = nil)
  if valid_604097 != nil:
    section.add "SubscriptionArn", valid_604097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604098: Call_PostSetSubscriptionAttributes_604083; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_604098.validator(path, query, header, formData, body)
  let scheme = call_604098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604098.url(scheme.get, call_604098.host, call_604098.base,
                         call_604098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604098, url, valid)

proc call*(call_604099: Call_PostSetSubscriptionAttributes_604083;
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
  var query_604100 = newJObject()
  var formData_604101 = newJObject()
  add(formData_604101, "AttributeName", newJString(AttributeName))
  add(formData_604101, "AttributeValue", newJString(AttributeValue))
  add(query_604100, "Action", newJString(Action))
  add(formData_604101, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_604100, "Version", newJString(Version))
  result = call_604099.call(nil, query_604100, nil, formData_604101, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_604083(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_604084, base: "/",
    url: url_PostSetSubscriptionAttributes_604085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_604065 = ref object of OpenApiRestCall_602466
proc url_GetSetSubscriptionAttributes_604067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSubscriptionAttributes_604066(path: JsonNode; query: JsonNode;
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
  var valid_604068 = query.getOrDefault("SubscriptionArn")
  valid_604068 = validateParameter(valid_604068, JString, required = true,
                                 default = nil)
  if valid_604068 != nil:
    section.add "SubscriptionArn", valid_604068
  var valid_604069 = query.getOrDefault("AttributeName")
  valid_604069 = validateParameter(valid_604069, JString, required = true,
                                 default = nil)
  if valid_604069 != nil:
    section.add "AttributeName", valid_604069
  var valid_604070 = query.getOrDefault("Action")
  valid_604070 = validateParameter(valid_604070, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_604070 != nil:
    section.add "Action", valid_604070
  var valid_604071 = query.getOrDefault("AttributeValue")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "AttributeValue", valid_604071
  var valid_604072 = query.getOrDefault("Version")
  valid_604072 = validateParameter(valid_604072, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604072 != nil:
    section.add "Version", valid_604072
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
  var valid_604073 = header.getOrDefault("X-Amz-Date")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Date", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Security-Token")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Security-Token", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Content-Sha256", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Algorithm")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Algorithm", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Signature")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Signature", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-SignedHeaders", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Credential")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Credential", valid_604079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604080: Call_GetSetSubscriptionAttributes_604065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_604080.validator(path, query, header, formData, body)
  let scheme = call_604080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604080.url(scheme.get, call_604080.host, call_604080.base,
                         call_604080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604080, url, valid)

proc call*(call_604081: Call_GetSetSubscriptionAttributes_604065;
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
  var query_604082 = newJObject()
  add(query_604082, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_604082, "AttributeName", newJString(AttributeName))
  add(query_604082, "Action", newJString(Action))
  add(query_604082, "AttributeValue", newJString(AttributeValue))
  add(query_604082, "Version", newJString(Version))
  result = call_604081.call(nil, query_604082, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_604065(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_604066, base: "/",
    url: url_GetSetSubscriptionAttributes_604067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_604120 = ref object of OpenApiRestCall_602466
proc url_PostSetTopicAttributes_604122(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetTopicAttributes_604121(path: JsonNode; query: JsonNode;
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
  var valid_604123 = query.getOrDefault("Action")
  valid_604123 = validateParameter(valid_604123, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_604123 != nil:
    section.add "Action", valid_604123
  var valid_604124 = query.getOrDefault("Version")
  valid_604124 = validateParameter(valid_604124, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604124 != nil:
    section.add "Version", valid_604124
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
  var valid_604125 = header.getOrDefault("X-Amz-Date")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Date", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-Security-Token")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Security-Token", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Content-Sha256", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-Algorithm")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Algorithm", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Signature")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Signature", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-SignedHeaders", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-Credential")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-Credential", valid_604131
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
  var valid_604132 = formData.getOrDefault("TopicArn")
  valid_604132 = validateParameter(valid_604132, JString, required = true,
                                 default = nil)
  if valid_604132 != nil:
    section.add "TopicArn", valid_604132
  var valid_604133 = formData.getOrDefault("AttributeName")
  valid_604133 = validateParameter(valid_604133, JString, required = true,
                                 default = nil)
  if valid_604133 != nil:
    section.add "AttributeName", valid_604133
  var valid_604134 = formData.getOrDefault("AttributeValue")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "AttributeValue", valid_604134
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604135: Call_PostSetTopicAttributes_604120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_604135.validator(path, query, header, formData, body)
  let scheme = call_604135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604135.url(scheme.get, call_604135.host, call_604135.base,
                         call_604135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604135, url, valid)

proc call*(call_604136: Call_PostSetTopicAttributes_604120; TopicArn: string;
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
  var query_604137 = newJObject()
  var formData_604138 = newJObject()
  add(formData_604138, "TopicArn", newJString(TopicArn))
  add(formData_604138, "AttributeName", newJString(AttributeName))
  add(formData_604138, "AttributeValue", newJString(AttributeValue))
  add(query_604137, "Action", newJString(Action))
  add(query_604137, "Version", newJString(Version))
  result = call_604136.call(nil, query_604137, nil, formData_604138, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_604120(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_604121, base: "/",
    url: url_PostSetTopicAttributes_604122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_604102 = ref object of OpenApiRestCall_602466
proc url_GetSetTopicAttributes_604104(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetTopicAttributes_604103(path: JsonNode; query: JsonNode;
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
  var valid_604105 = query.getOrDefault("AttributeName")
  valid_604105 = validateParameter(valid_604105, JString, required = true,
                                 default = nil)
  if valid_604105 != nil:
    section.add "AttributeName", valid_604105
  var valid_604106 = query.getOrDefault("Action")
  valid_604106 = validateParameter(valid_604106, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_604106 != nil:
    section.add "Action", valid_604106
  var valid_604107 = query.getOrDefault("AttributeValue")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "AttributeValue", valid_604107
  var valid_604108 = query.getOrDefault("TopicArn")
  valid_604108 = validateParameter(valid_604108, JString, required = true,
                                 default = nil)
  if valid_604108 != nil:
    section.add "TopicArn", valid_604108
  var valid_604109 = query.getOrDefault("Version")
  valid_604109 = validateParameter(valid_604109, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604109 != nil:
    section.add "Version", valid_604109
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
  var valid_604110 = header.getOrDefault("X-Amz-Date")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Date", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Security-Token")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Security-Token", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Content-Sha256", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Algorithm")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Algorithm", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Signature")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Signature", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-SignedHeaders", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-Credential")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-Credential", valid_604116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604117: Call_GetSetTopicAttributes_604102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_604117.validator(path, query, header, formData, body)
  let scheme = call_604117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604117.url(scheme.get, call_604117.host, call_604117.base,
                         call_604117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604117, url, valid)

proc call*(call_604118: Call_GetSetTopicAttributes_604102; AttributeName: string;
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
  var query_604119 = newJObject()
  add(query_604119, "AttributeName", newJString(AttributeName))
  add(query_604119, "Action", newJString(Action))
  add(query_604119, "AttributeValue", newJString(AttributeValue))
  add(query_604119, "TopicArn", newJString(TopicArn))
  add(query_604119, "Version", newJString(Version))
  result = call_604118.call(nil, query_604119, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_604102(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_604103, base: "/",
    url: url_GetSetTopicAttributes_604104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_604164 = ref object of OpenApiRestCall_602466
proc url_PostSubscribe_604166(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSubscribe_604165(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604167 = query.getOrDefault("Action")
  valid_604167 = validateParameter(valid_604167, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_604167 != nil:
    section.add "Action", valid_604167
  var valid_604168 = query.getOrDefault("Version")
  valid_604168 = validateParameter(valid_604168, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604168 != nil:
    section.add "Version", valid_604168
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
  var valid_604169 = header.getOrDefault("X-Amz-Date")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-Date", valid_604169
  var valid_604170 = header.getOrDefault("X-Amz-Security-Token")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Security-Token", valid_604170
  var valid_604171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-Content-Sha256", valid_604171
  var valid_604172 = header.getOrDefault("X-Amz-Algorithm")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-Algorithm", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-Signature")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-Signature", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-SignedHeaders", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Credential")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Credential", valid_604175
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
  var valid_604176 = formData.getOrDefault("Endpoint")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "Endpoint", valid_604176
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_604177 = formData.getOrDefault("TopicArn")
  valid_604177 = validateParameter(valid_604177, JString, required = true,
                                 default = nil)
  if valid_604177 != nil:
    section.add "TopicArn", valid_604177
  var valid_604178 = formData.getOrDefault("Attributes.0.value")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "Attributes.0.value", valid_604178
  var valid_604179 = formData.getOrDefault("Protocol")
  valid_604179 = validateParameter(valid_604179, JString, required = true,
                                 default = nil)
  if valid_604179 != nil:
    section.add "Protocol", valid_604179
  var valid_604180 = formData.getOrDefault("Attributes.0.key")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "Attributes.0.key", valid_604180
  var valid_604181 = formData.getOrDefault("Attributes.1.key")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "Attributes.1.key", valid_604181
  var valid_604182 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_604182 = validateParameter(valid_604182, JBool, required = false, default = nil)
  if valid_604182 != nil:
    section.add "ReturnSubscriptionArn", valid_604182
  var valid_604183 = formData.getOrDefault("Attributes.2.value")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "Attributes.2.value", valid_604183
  var valid_604184 = formData.getOrDefault("Attributes.2.key")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "Attributes.2.key", valid_604184
  var valid_604185 = formData.getOrDefault("Attributes.1.value")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "Attributes.1.value", valid_604185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604186: Call_PostSubscribe_604164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_604186.validator(path, query, header, formData, body)
  let scheme = call_604186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604186.url(scheme.get, call_604186.host, call_604186.base,
                         call_604186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604186, url, valid)

proc call*(call_604187: Call_PostSubscribe_604164; TopicArn: string;
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
  var query_604188 = newJObject()
  var formData_604189 = newJObject()
  add(formData_604189, "Endpoint", newJString(Endpoint))
  add(formData_604189, "TopicArn", newJString(TopicArn))
  add(formData_604189, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_604189, "Protocol", newJString(Protocol))
  add(formData_604189, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_604189, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_604189, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_604188, "Action", newJString(Action))
  add(formData_604189, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_604189, "Attributes.2.key", newJString(Attributes2Key))
  add(query_604188, "Version", newJString(Version))
  add(formData_604189, "Attributes.1.value", newJString(Attributes1Value))
  result = call_604187.call(nil, query_604188, nil, formData_604189, nil)

var postSubscribe* = Call_PostSubscribe_604164(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_604165,
    base: "/", url: url_PostSubscribe_604166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_604139 = ref object of OpenApiRestCall_602466
proc url_GetSubscribe_604141(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSubscribe_604140(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604142 = query.getOrDefault("Attributes.2.key")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "Attributes.2.key", valid_604142
  var valid_604143 = query.getOrDefault("Endpoint")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "Endpoint", valid_604143
  assert query != nil,
        "query argument is necessary due to required `Protocol` field"
  var valid_604144 = query.getOrDefault("Protocol")
  valid_604144 = validateParameter(valid_604144, JString, required = true,
                                 default = nil)
  if valid_604144 != nil:
    section.add "Protocol", valid_604144
  var valid_604145 = query.getOrDefault("Attributes.1.value")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "Attributes.1.value", valid_604145
  var valid_604146 = query.getOrDefault("Attributes.0.value")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "Attributes.0.value", valid_604146
  var valid_604147 = query.getOrDefault("Action")
  valid_604147 = validateParameter(valid_604147, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_604147 != nil:
    section.add "Action", valid_604147
  var valid_604148 = query.getOrDefault("ReturnSubscriptionArn")
  valid_604148 = validateParameter(valid_604148, JBool, required = false, default = nil)
  if valid_604148 != nil:
    section.add "ReturnSubscriptionArn", valid_604148
  var valid_604149 = query.getOrDefault("Attributes.1.key")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "Attributes.1.key", valid_604149
  var valid_604150 = query.getOrDefault("TopicArn")
  valid_604150 = validateParameter(valid_604150, JString, required = true,
                                 default = nil)
  if valid_604150 != nil:
    section.add "TopicArn", valid_604150
  var valid_604151 = query.getOrDefault("Attributes.2.value")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "Attributes.2.value", valid_604151
  var valid_604152 = query.getOrDefault("Attributes.0.key")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "Attributes.0.key", valid_604152
  var valid_604153 = query.getOrDefault("Version")
  valid_604153 = validateParameter(valid_604153, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604153 != nil:
    section.add "Version", valid_604153
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
  var valid_604154 = header.getOrDefault("X-Amz-Date")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = nil)
  if valid_604154 != nil:
    section.add "X-Amz-Date", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-Security-Token")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Security-Token", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Content-Sha256", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Algorithm")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Algorithm", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-Signature")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Signature", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-SignedHeaders", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Credential")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Credential", valid_604160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604161: Call_GetSubscribe_604139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_604161.validator(path, query, header, formData, body)
  let scheme = call_604161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604161.url(scheme.get, call_604161.host, call_604161.base,
                         call_604161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604161, url, valid)

proc call*(call_604162: Call_GetSubscribe_604139; Protocol: string; TopicArn: string;
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
  var query_604163 = newJObject()
  add(query_604163, "Attributes.2.key", newJString(Attributes2Key))
  add(query_604163, "Endpoint", newJString(Endpoint))
  add(query_604163, "Protocol", newJString(Protocol))
  add(query_604163, "Attributes.1.value", newJString(Attributes1Value))
  add(query_604163, "Attributes.0.value", newJString(Attributes0Value))
  add(query_604163, "Action", newJString(Action))
  add(query_604163, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_604163, "Attributes.1.key", newJString(Attributes1Key))
  add(query_604163, "TopicArn", newJString(TopicArn))
  add(query_604163, "Attributes.2.value", newJString(Attributes2Value))
  add(query_604163, "Attributes.0.key", newJString(Attributes0Key))
  add(query_604163, "Version", newJString(Version))
  result = call_604162.call(nil, query_604163, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_604139(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_604140, base: "/",
    url: url_GetSubscribe_604141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_604207 = ref object of OpenApiRestCall_602466
proc url_PostTagResource_604209(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTagResource_604208(path: JsonNode; query: JsonNode;
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
  var valid_604210 = query.getOrDefault("Action")
  valid_604210 = validateParameter(valid_604210, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_604210 != nil:
    section.add "Action", valid_604210
  var valid_604211 = query.getOrDefault("Version")
  valid_604211 = validateParameter(valid_604211, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604211 != nil:
    section.add "Version", valid_604211
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
  var valid_604212 = header.getOrDefault("X-Amz-Date")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Date", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Security-Token")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Security-Token", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Content-Sha256", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Algorithm")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Algorithm", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Signature")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Signature", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-SignedHeaders", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-Credential")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-Credential", valid_604218
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_604219 = formData.getOrDefault("Tags")
  valid_604219 = validateParameter(valid_604219, JArray, required = true, default = nil)
  if valid_604219 != nil:
    section.add "Tags", valid_604219
  var valid_604220 = formData.getOrDefault("ResourceArn")
  valid_604220 = validateParameter(valid_604220, JString, required = true,
                                 default = nil)
  if valid_604220 != nil:
    section.add "ResourceArn", valid_604220
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604221: Call_PostTagResource_604207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_604221.validator(path, query, header, formData, body)
  let scheme = call_604221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604221.url(scheme.get, call_604221.host, call_604221.base,
                         call_604221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604221, url, valid)

proc call*(call_604222: Call_PostTagResource_604207; Tags: JsonNode;
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
  var query_604223 = newJObject()
  var formData_604224 = newJObject()
  if Tags != nil:
    formData_604224.add "Tags", Tags
  add(query_604223, "Action", newJString(Action))
  add(formData_604224, "ResourceArn", newJString(ResourceArn))
  add(query_604223, "Version", newJString(Version))
  result = call_604222.call(nil, query_604223, nil, formData_604224, nil)

var postTagResource* = Call_PostTagResource_604207(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_604208,
    base: "/", url: url_PostTagResource_604209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_604190 = ref object of OpenApiRestCall_602466
proc url_GetTagResource_604192(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagResource_604191(path: JsonNode; query: JsonNode;
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
  var valid_604193 = query.getOrDefault("ResourceArn")
  valid_604193 = validateParameter(valid_604193, JString, required = true,
                                 default = nil)
  if valid_604193 != nil:
    section.add "ResourceArn", valid_604193
  var valid_604194 = query.getOrDefault("Tags")
  valid_604194 = validateParameter(valid_604194, JArray, required = true, default = nil)
  if valid_604194 != nil:
    section.add "Tags", valid_604194
  var valid_604195 = query.getOrDefault("Action")
  valid_604195 = validateParameter(valid_604195, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_604195 != nil:
    section.add "Action", valid_604195
  var valid_604196 = query.getOrDefault("Version")
  valid_604196 = validateParameter(valid_604196, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604196 != nil:
    section.add "Version", valid_604196
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
  var valid_604197 = header.getOrDefault("X-Amz-Date")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Date", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Security-Token")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Security-Token", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Content-Sha256", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Algorithm")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Algorithm", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Signature")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Signature", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-SignedHeaders", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-Credential")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-Credential", valid_604203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604204: Call_GetTagResource_604190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_604204.validator(path, query, header, formData, body)
  let scheme = call_604204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604204.url(scheme.get, call_604204.host, call_604204.base,
                         call_604204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604204, url, valid)

proc call*(call_604205: Call_GetTagResource_604190; ResourceArn: string;
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
  var query_604206 = newJObject()
  add(query_604206, "ResourceArn", newJString(ResourceArn))
  if Tags != nil:
    query_604206.add "Tags", Tags
  add(query_604206, "Action", newJString(Action))
  add(query_604206, "Version", newJString(Version))
  result = call_604205.call(nil, query_604206, nil, nil, nil)

var getTagResource* = Call_GetTagResource_604190(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_604191,
    base: "/", url: url_GetTagResource_604192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_604241 = ref object of OpenApiRestCall_602466
proc url_PostUnsubscribe_604243(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUnsubscribe_604242(path: JsonNode; query: JsonNode;
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
  var valid_604244 = query.getOrDefault("Action")
  valid_604244 = validateParameter(valid_604244, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_604244 != nil:
    section.add "Action", valid_604244
  var valid_604245 = query.getOrDefault("Version")
  valid_604245 = validateParameter(valid_604245, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604245 != nil:
    section.add "Version", valid_604245
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
  var valid_604246 = header.getOrDefault("X-Amz-Date")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Date", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-Security-Token")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Security-Token", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Content-Sha256", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Algorithm")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Algorithm", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Signature")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Signature", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-SignedHeaders", valid_604251
  var valid_604252 = header.getOrDefault("X-Amz-Credential")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-Credential", valid_604252
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_604253 = formData.getOrDefault("SubscriptionArn")
  valid_604253 = validateParameter(valid_604253, JString, required = true,
                                 default = nil)
  if valid_604253 != nil:
    section.add "SubscriptionArn", valid_604253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604254: Call_PostUnsubscribe_604241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_604254.validator(path, query, header, formData, body)
  let scheme = call_604254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604254.url(scheme.get, call_604254.host, call_604254.base,
                         call_604254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604254, url, valid)

proc call*(call_604255: Call_PostUnsubscribe_604241; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Version: string (required)
  var query_604256 = newJObject()
  var formData_604257 = newJObject()
  add(query_604256, "Action", newJString(Action))
  add(formData_604257, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_604256, "Version", newJString(Version))
  result = call_604255.call(nil, query_604256, nil, formData_604257, nil)

var postUnsubscribe* = Call_PostUnsubscribe_604241(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_604242,
    base: "/", url: url_PostUnsubscribe_604243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_604225 = ref object of OpenApiRestCall_602466
proc url_GetUnsubscribe_604227(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUnsubscribe_604226(path: JsonNode; query: JsonNode;
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
  var valid_604228 = query.getOrDefault("SubscriptionArn")
  valid_604228 = validateParameter(valid_604228, JString, required = true,
                                 default = nil)
  if valid_604228 != nil:
    section.add "SubscriptionArn", valid_604228
  var valid_604229 = query.getOrDefault("Action")
  valid_604229 = validateParameter(valid_604229, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_604229 != nil:
    section.add "Action", valid_604229
  var valid_604230 = query.getOrDefault("Version")
  valid_604230 = validateParameter(valid_604230, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604230 != nil:
    section.add "Version", valid_604230
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
  var valid_604231 = header.getOrDefault("X-Amz-Date")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Date", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-Security-Token")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Security-Token", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Content-Sha256", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Algorithm")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Algorithm", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-Signature")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-Signature", valid_604235
  var valid_604236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "X-Amz-SignedHeaders", valid_604236
  var valid_604237 = header.getOrDefault("X-Amz-Credential")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "X-Amz-Credential", valid_604237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604238: Call_GetUnsubscribe_604225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_604238.validator(path, query, header, formData, body)
  let scheme = call_604238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604238.url(scheme.get, call_604238.host, call_604238.base,
                         call_604238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604238, url, valid)

proc call*(call_604239: Call_GetUnsubscribe_604225; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604240 = newJObject()
  add(query_604240, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_604240, "Action", newJString(Action))
  add(query_604240, "Version", newJString(Version))
  result = call_604239.call(nil, query_604240, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_604225(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_604226,
    base: "/", url: url_GetUnsubscribe_604227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_604275 = ref object of OpenApiRestCall_602466
proc url_PostUntagResource_604277(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUntagResource_604276(path: JsonNode; query: JsonNode;
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
  var valid_604278 = query.getOrDefault("Action")
  valid_604278 = validateParameter(valid_604278, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_604278 != nil:
    section.add "Action", valid_604278
  var valid_604279 = query.getOrDefault("Version")
  valid_604279 = validateParameter(valid_604279, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604279 != nil:
    section.add "Version", valid_604279
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
  var valid_604280 = header.getOrDefault("X-Amz-Date")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Date", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-Security-Token")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Security-Token", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Content-Sha256", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-Algorithm")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Algorithm", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Signature")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Signature", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-SignedHeaders", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Credential")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Credential", valid_604286
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604287 = formData.getOrDefault("TagKeys")
  valid_604287 = validateParameter(valid_604287, JArray, required = true, default = nil)
  if valid_604287 != nil:
    section.add "TagKeys", valid_604287
  var valid_604288 = formData.getOrDefault("ResourceArn")
  valid_604288 = validateParameter(valid_604288, JString, required = true,
                                 default = nil)
  if valid_604288 != nil:
    section.add "ResourceArn", valid_604288
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604289: Call_PostUntagResource_604275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_604289.validator(path, query, header, formData, body)
  let scheme = call_604289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604289.url(scheme.get, call_604289.host, call_604289.base,
                         call_604289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604289, url, valid)

proc call*(call_604290: Call_PostUntagResource_604275; TagKeys: JsonNode;
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
  var query_604291 = newJObject()
  var formData_604292 = newJObject()
  add(query_604291, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604292.add "TagKeys", TagKeys
  add(formData_604292, "ResourceArn", newJString(ResourceArn))
  add(query_604291, "Version", newJString(Version))
  result = call_604290.call(nil, query_604291, nil, formData_604292, nil)

var postUntagResource* = Call_PostUntagResource_604275(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_604276,
    base: "/", url: url_PostUntagResource_604277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_604258 = ref object of OpenApiRestCall_602466
proc url_GetUntagResource_604260(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUntagResource_604259(path: JsonNode; query: JsonNode;
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
  var valid_604261 = query.getOrDefault("ResourceArn")
  valid_604261 = validateParameter(valid_604261, JString, required = true,
                                 default = nil)
  if valid_604261 != nil:
    section.add "ResourceArn", valid_604261
  var valid_604262 = query.getOrDefault("Action")
  valid_604262 = validateParameter(valid_604262, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_604262 != nil:
    section.add "Action", valid_604262
  var valid_604263 = query.getOrDefault("TagKeys")
  valid_604263 = validateParameter(valid_604263, JArray, required = true, default = nil)
  if valid_604263 != nil:
    section.add "TagKeys", valid_604263
  var valid_604264 = query.getOrDefault("Version")
  valid_604264 = validateParameter(valid_604264, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604264 != nil:
    section.add "Version", valid_604264
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
  var valid_604265 = header.getOrDefault("X-Amz-Date")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Date", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-Security-Token")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-Security-Token", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Content-Sha256", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-Algorithm")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Algorithm", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-Signature")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-Signature", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-SignedHeaders", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Credential")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Credential", valid_604271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604272: Call_GetUntagResource_604258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_604272.validator(path, query, header, formData, body)
  let scheme = call_604272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604272.url(scheme.get, call_604272.host, call_604272.base,
                         call_604272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604272, url, valid)

proc call*(call_604273: Call_GetUntagResource_604258; ResourceArn: string;
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
  var query_604274 = newJObject()
  add(query_604274, "ResourceArn", newJString(ResourceArn))
  add(query_604274, "Action", newJString(Action))
  if TagKeys != nil:
    query_604274.add "TagKeys", TagKeys
  add(query_604274, "Version", newJString(Version))
  result = call_604273.call(nil, query_604274, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_604258(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_604259,
    base: "/", url: url_GetUntagResource_604260,
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
