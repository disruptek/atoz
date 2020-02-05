
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Pinpoint Email Service
## version: 2018-07-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Pinpoint Email Service</fullname> <p>Welcome to the <i>Amazon Pinpoint Email API Reference</i>. This guide provides information about the Amazon Pinpoint Email API (version 1.0), including supported operations, data types, parameters, and schemas.</p> <p> <a href="https://aws.amazon.com/pinpoint">Amazon Pinpoint</a> is an AWS service that you can use to engage with your customers across multiple messaging channels. You can use Amazon Pinpoint to send email, SMS text messages, voice messages, and push notifications. The Amazon Pinpoint Email API provides programmatic access to options that are unique to the email channel and supplement the options provided by the Amazon Pinpoint API.</p> <p>If you're new to Amazon Pinpoint, you might find it helpful to also review the <a href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>. The <i>Amazon Pinpoint Developer Guide</i> provides tutorials, code samples, and procedures that demonstrate how to use Amazon Pinpoint features programmatically and how to integrate Amazon Pinpoint functionality into mobile apps and other types of applications. The guide also provides information about key topics such as Amazon Pinpoint integration with other AWS services and the limits that apply to using the service.</p> <p>The Amazon Pinpoint Email API is available in several AWS Regions and it provides an endpoint for each of these Regions. For a list of all the Regions and endpoints where the API is currently available, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#pinpoint_region">AWS Service Endpoints</a> in the <i>Amazon Web Services General Reference</i>. To learn more about AWS Regions, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande-manage.html">Managing AWS Regions</a> in the <i>Amazon Web Services General Reference</i>.</p> <p>In each Region, AWS maintains multiple Availability Zones. These Availability Zones are physically isolated from each other, but are united by private, low-latency, high-throughput, and highly redundant network connections. These Availability Zones enable us to provide very high levels of availability and redundancy, while also minimizing latency. To learn more about the number of Availability Zones that are available in each Region, see <a href="http://aws.amazon.com/about-aws/global-infrastructure/">AWS Global Infrastructure</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/email/
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "email.ap-northeast-1.amazonaws.com", "ap-southeast-1": "email.ap-southeast-1.amazonaws.com",
                           "us-west-2": "email.us-west-2.amazonaws.com",
                           "eu-west-2": "email.eu-west-2.amazonaws.com", "ap-northeast-3": "email.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "email.eu-central-1.amazonaws.com",
                           "us-east-2": "email.us-east-2.amazonaws.com",
                           "us-east-1": "email.us-east-1.amazonaws.com", "cn-northwest-1": "email.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "email.ap-south-1.amazonaws.com",
                           "eu-north-1": "email.eu-north-1.amazonaws.com", "ap-northeast-2": "email.ap-northeast-2.amazonaws.com",
                           "us-west-1": "email.us-west-1.amazonaws.com", "us-gov-east-1": "email.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "email.eu-west-3.amazonaws.com",
                           "cn-north-1": "email.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "email.sa-east-1.amazonaws.com",
                           "eu-west-1": "email.eu-west-1.amazonaws.com", "us-gov-west-1": "email.us-gov-west-1.amazonaws.com", "ap-southeast-2": "email.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "email.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "email.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "email.ap-southeast-1.amazonaws.com",
      "us-west-2": "email.us-west-2.amazonaws.com",
      "eu-west-2": "email.eu-west-2.amazonaws.com",
      "ap-northeast-3": "email.ap-northeast-3.amazonaws.com",
      "eu-central-1": "email.eu-central-1.amazonaws.com",
      "us-east-2": "email.us-east-2.amazonaws.com",
      "us-east-1": "email.us-east-1.amazonaws.com",
      "cn-northwest-1": "email.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "email.ap-south-1.amazonaws.com",
      "eu-north-1": "email.eu-north-1.amazonaws.com",
      "ap-northeast-2": "email.ap-northeast-2.amazonaws.com",
      "us-west-1": "email.us-west-1.amazonaws.com",
      "us-gov-east-1": "email.us-gov-east-1.amazonaws.com",
      "eu-west-3": "email.eu-west-3.amazonaws.com",
      "cn-north-1": "email.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "email.sa-east-1.amazonaws.com",
      "eu-west-1": "email.eu-west-1.amazonaws.com",
      "us-gov-west-1": "email.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "email.ap-southeast-2.amazonaws.com",
      "ca-central-1": "email.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "pinpoint-email"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateConfigurationSet_613253 = ref object of OpenApiRestCall_612658
proc url_CreateConfigurationSet_613255(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfigurationSet_613254(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613256 = header.getOrDefault("X-Amz-Signature")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Signature", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Content-Sha256", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Date")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Date", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Credential")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Credential", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Security-Token")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Security-Token", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Algorithm")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Algorithm", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-SignedHeaders", valid_613262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613264: Call_CreateConfigurationSet_613253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  let valid = call_613264.validator(path, query, header, formData, body)
  let scheme = call_613264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613264.url(scheme.get, call_613264.host, call_613264.base,
                         call_613264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613264, url, valid)

proc call*(call_613265: Call_CreateConfigurationSet_613253; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ##   body: JObject (required)
  var body_613266 = newJObject()
  if body != nil:
    body_613266 = body
  result = call_613265.call(nil, nil, nil, nil, body_613266)

var createConfigurationSet* = Call_CreateConfigurationSet_613253(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_CreateConfigurationSet_613254, base: "/",
    url: url_CreateConfigurationSet_613255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_612996 = ref object of OpenApiRestCall_612658
proc url_ListConfigurationSets_612998(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurationSets_612997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  section = newJObject()
  var valid_613110 = query.getOrDefault("NextToken")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "NextToken", valid_613110
  var valid_613111 = query.getOrDefault("PageSize")
  valid_613111 = validateParameter(valid_613111, JInt, required = false, default = nil)
  if valid_613111 != nil:
    section.add "PageSize", valid_613111
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
  var valid_613112 = header.getOrDefault("X-Amz-Signature")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Signature", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Content-Sha256", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Date")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Date", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Credential")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Credential", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Security-Token")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Security-Token", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Algorithm")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Algorithm", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-SignedHeaders", valid_613118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613141: Call_ListConfigurationSets_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_613141.validator(path, query, header, formData, body)
  let scheme = call_613141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613141.url(scheme.get, call_613141.host, call_613141.base,
                         call_613141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613141, url, valid)

proc call*(call_613212: Call_ListConfigurationSets_612996; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listConfigurationSets
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  var query_613213 = newJObject()
  add(query_613213, "NextToken", newJString(NextToken))
  add(query_613213, "PageSize", newJInt(PageSize))
  result = call_613212.call(nil, query_613213, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_612996(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_ListConfigurationSets_612997, base: "/",
    url: url_ListConfigurationSets_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_613295 = ref object of OpenApiRestCall_612658
proc url_CreateConfigurationSetEventDestination_613297(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_613296(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613298 = path.getOrDefault("ConfigurationSetName")
  valid_613298 = validateParameter(valid_613298, JString, required = true,
                                 default = nil)
  if valid_613298 != nil:
    section.add "ConfigurationSetName", valid_613298
  result.add "path", section
  section = newJObject()
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
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_CreateConfigurationSetEventDestination_613295;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateConfigurationSetEventDestination_613295;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_613309 = newJObject()
  var body_613310 = newJObject()
  add(path_613309, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_613310 = body
  result = call_613308.call(path_613309, nil, nil, nil, body_613310)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_613295(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_613296, base: "/",
    url: url_CreateConfigurationSetEventDestination_613297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_613267 = ref object of OpenApiRestCall_612658
proc url_GetConfigurationSetEventDestinations_613269(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_613268(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613284 = path.getOrDefault("ConfigurationSetName")
  valid_613284 = validateParameter(valid_613284, JString, required = true,
                                 default = nil)
  if valid_613284 != nil:
    section.add "ConfigurationSetName", valid_613284
  result.add "path", section
  section = newJObject()
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
  var valid_613285 = header.getOrDefault("X-Amz-Signature")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Signature", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Content-Sha256", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Date")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Date", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Credential")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Credential", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Security-Token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Security-Token", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Algorithm")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Algorithm", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-SignedHeaders", valid_613291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_GetConfigurationSetEventDestinations_613267;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_GetConfigurationSetEventDestinations_613267;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_613294 = newJObject()
  add(path_613294, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_613293.call(path_613294, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_613267(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_613268, base: "/",
    url: url_GetConfigurationSetEventDestinations_613269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDedicatedIpPool_613326 = ref object of OpenApiRestCall_612658
proc url_CreateDedicatedIpPool_613328(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDedicatedIpPool_613327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_CreateDedicatedIpPool_613326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_CreateDedicatedIpPool_613326; body: JsonNode): Recallable =
  ## createDedicatedIpPool
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var createDedicatedIpPool* = Call_CreateDedicatedIpPool_613326(
    name: "createDedicatedIpPool", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_CreateDedicatedIpPool_613327, base: "/",
    url: url_CreateDedicatedIpPool_613328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDedicatedIpPools_613311 = ref object of OpenApiRestCall_612658
proc url_ListDedicatedIpPools_613313(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDedicatedIpPools_613312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  section = newJObject()
  var valid_613314 = query.getOrDefault("NextToken")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "NextToken", valid_613314
  var valid_613315 = query.getOrDefault("PageSize")
  valid_613315 = validateParameter(valid_613315, JInt, required = false, default = nil)
  if valid_613315 != nil:
    section.add "PageSize", valid_613315
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
  var valid_613316 = header.getOrDefault("X-Amz-Signature")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Signature", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Content-Sha256", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Date")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Date", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Credential")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Credential", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Security-Token")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Security-Token", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Algorithm")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Algorithm", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-SignedHeaders", valid_613322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613323: Call_ListDedicatedIpPools_613311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_613323.validator(path, query, header, formData, body)
  let scheme = call_613323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613323.url(scheme.get, call_613323.host, call_613323.base,
                         call_613323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613323, url, valid)

proc call*(call_613324: Call_ListDedicatedIpPools_613311; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listDedicatedIpPools
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  var query_613325 = newJObject()
  add(query_613325, "NextToken", newJString(NextToken))
  add(query_613325, "PageSize", newJInt(PageSize))
  result = call_613324.call(nil, query_613325, nil, nil, nil)

var listDedicatedIpPools* = Call_ListDedicatedIpPools_613311(
    name: "listDedicatedIpPools", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_ListDedicatedIpPools_613312, base: "/",
    url: url_ListDedicatedIpPools_613313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeliverabilityTestReport_613340 = ref object of OpenApiRestCall_612658
proc url_CreateDeliverabilityTestReport_613342(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeliverabilityTestReport_613341(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613343 = header.getOrDefault("X-Amz-Signature")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Signature", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Content-Sha256", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Date")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Date", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Credential")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Credential", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Security-Token")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Security-Token", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Algorithm")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Algorithm", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-SignedHeaders", valid_613349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613351: Call_CreateDeliverabilityTestReport_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  let valid = call_613351.validator(path, query, header, formData, body)
  let scheme = call_613351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613351.url(scheme.get, call_613351.host, call_613351.base,
                         call_613351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613351, url, valid)

proc call*(call_613352: Call_CreateDeliverabilityTestReport_613340; body: JsonNode): Recallable =
  ## createDeliverabilityTestReport
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ##   body: JObject (required)
  var body_613353 = newJObject()
  if body != nil:
    body_613353 = body
  result = call_613352.call(nil, nil, nil, nil, body_613353)

var createDeliverabilityTestReport* = Call_CreateDeliverabilityTestReport_613340(
    name: "createDeliverabilityTestReport", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/test",
    validator: validate_CreateDeliverabilityTestReport_613341, base: "/",
    url: url_CreateDeliverabilityTestReport_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailIdentity_613369 = ref object of OpenApiRestCall_612658
proc url_CreateEmailIdentity_613371(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEmailIdentity_613370(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613372 = header.getOrDefault("X-Amz-Signature")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Signature", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Content-Sha256", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Date")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Date", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Credential")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Credential", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Security-Token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Security-Token", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Algorithm")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Algorithm", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-SignedHeaders", valid_613378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613380: Call_CreateEmailIdentity_613369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ## 
  let valid = call_613380.validator(path, query, header, formData, body)
  let scheme = call_613380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613380.url(scheme.get, call_613380.host, call_613380.base,
                         call_613380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613380, url, valid)

proc call*(call_613381: Call_CreateEmailIdentity_613369; body: JsonNode): Recallable =
  ## createEmailIdentity
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ##   body: JObject (required)
  var body_613382 = newJObject()
  if body != nil:
    body_613382 = body
  result = call_613381.call(nil, nil, nil, nil, body_613382)

var createEmailIdentity* = Call_CreateEmailIdentity_613369(
    name: "createEmailIdentity", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_CreateEmailIdentity_613370, base: "/",
    url: url_CreateEmailIdentity_613371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEmailIdentities_613354 = ref object of OpenApiRestCall_612658
proc url_ListEmailIdentities_613356(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEmailIdentities_613355(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  ##   PageSize: JInt
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  section = newJObject()
  var valid_613357 = query.getOrDefault("NextToken")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "NextToken", valid_613357
  var valid_613358 = query.getOrDefault("PageSize")
  valid_613358 = validateParameter(valid_613358, JInt, required = false, default = nil)
  if valid_613358 != nil:
    section.add "PageSize", valid_613358
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
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613366: Call_ListEmailIdentities_613354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ## 
  let valid = call_613366.validator(path, query, header, formData, body)
  let scheme = call_613366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613366.url(scheme.get, call_613366.host, call_613366.base,
                         call_613366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613366, url, valid)

proc call*(call_613367: Call_ListEmailIdentities_613354; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listEmailIdentities
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  var query_613368 = newJObject()
  add(query_613368, "NextToken", newJString(NextToken))
  add(query_613368, "PageSize", newJInt(PageSize))
  result = call_613367.call(nil, query_613368, nil, nil, nil)

var listEmailIdentities* = Call_ListEmailIdentities_613354(
    name: "listEmailIdentities", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_ListEmailIdentities_613355, base: "/",
    url: url_ListEmailIdentities_613356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSet_613383 = ref object of OpenApiRestCall_612658
proc url_GetConfigurationSet_613385(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSet_613384(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613386 = path.getOrDefault("ConfigurationSetName")
  valid_613386 = validateParameter(valid_613386, JString, required = true,
                                 default = nil)
  if valid_613386 != nil:
    section.add "ConfigurationSetName", valid_613386
  result.add "path", section
  section = newJObject()
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
  var valid_613387 = header.getOrDefault("X-Amz-Signature")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Signature", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Content-Sha256", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Date")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Date", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Credential")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Credential", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Security-Token")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Security-Token", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Algorithm")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Algorithm", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-SignedHeaders", valid_613393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613394: Call_GetConfigurationSet_613383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_613394.validator(path, query, header, formData, body)
  let scheme = call_613394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613394.url(scheme.get, call_613394.host, call_613394.base,
                         call_613394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613394, url, valid)

proc call*(call_613395: Call_GetConfigurationSet_613383;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSet
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_613396 = newJObject()
  add(path_613396, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_613395.call(path_613396, nil, nil, nil, nil)

var getConfigurationSet* = Call_GetConfigurationSet_613383(
    name: "getConfigurationSet", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_GetConfigurationSet_613384, base: "/",
    url: url_GetConfigurationSet_613385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_613397 = ref object of OpenApiRestCall_612658
proc url_DeleteConfigurationSet_613399(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_613398(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613400 = path.getOrDefault("ConfigurationSetName")
  valid_613400 = validateParameter(valid_613400, JString, required = true,
                                 default = nil)
  if valid_613400 != nil:
    section.add "ConfigurationSetName", valid_613400
  result.add "path", section
  section = newJObject()
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
  var valid_613401 = header.getOrDefault("X-Amz-Signature")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Signature", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Content-Sha256", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Date")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Date", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Credential")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Credential", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Security-Token")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Security-Token", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Algorithm")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Algorithm", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-SignedHeaders", valid_613407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613408: Call_DeleteConfigurationSet_613397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_613408.validator(path, query, header, formData, body)
  let scheme = call_613408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613408.url(scheme.get, call_613408.host, call_613408.base,
                         call_613408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613408, url, valid)

proc call*(call_613409: Call_DeleteConfigurationSet_613397;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_613410 = newJObject()
  add(path_613410, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_613409.call(path_613410, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_613397(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_613398, base: "/",
    url: url_DeleteConfigurationSet_613399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_613411 = ref object of OpenApiRestCall_612658
proc url_UpdateConfigurationSetEventDestination_613413(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  assert "EventDestinationName" in path,
        "`EventDestinationName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations/"),
               (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfigurationSetEventDestination_613412(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: JString (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613414 = path.getOrDefault("ConfigurationSetName")
  valid_613414 = validateParameter(valid_613414, JString, required = true,
                                 default = nil)
  if valid_613414 != nil:
    section.add "ConfigurationSetName", valid_613414
  var valid_613415 = path.getOrDefault("EventDestinationName")
  valid_613415 = validateParameter(valid_613415, JString, required = true,
                                 default = nil)
  if valid_613415 != nil:
    section.add "EventDestinationName", valid_613415
  result.add "path", section
  section = newJObject()
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
  var valid_613416 = header.getOrDefault("X-Amz-Signature")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Signature", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Content-Sha256", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Date")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Date", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Credential")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Credential", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Security-Token")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Security-Token", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Algorithm")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Algorithm", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-SignedHeaders", valid_613422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613424: Call_UpdateConfigurationSetEventDestination_613411;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_613424.validator(path, query, header, formData, body)
  let scheme = call_613424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613424.url(scheme.get, call_613424.host, call_613424.base,
                         call_613424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613424, url, valid)

proc call*(call_613425: Call_UpdateConfigurationSetEventDestination_613411;
          ConfigurationSetName: string; EventDestinationName: string; body: JsonNode): Recallable =
  ## updateConfigurationSetEventDestination
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   body: JObject (required)
  var path_613426 = newJObject()
  var body_613427 = newJObject()
  add(path_613426, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_613426, "EventDestinationName", newJString(EventDestinationName))
  if body != nil:
    body_613427 = body
  result = call_613425.call(path_613426, nil, nil, nil, body_613427)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_613411(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_613412, base: "/",
    url: url_UpdateConfigurationSetEventDestination_613413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_613428 = ref object of OpenApiRestCall_612658
proc url_DeleteConfigurationSetEventDestination_613430(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  assert "EventDestinationName" in path,
        "`EventDestinationName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations/"),
               (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSetEventDestination_613429(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: JString (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613431 = path.getOrDefault("ConfigurationSetName")
  valid_613431 = validateParameter(valid_613431, JString, required = true,
                                 default = nil)
  if valid_613431 != nil:
    section.add "ConfigurationSetName", valid_613431
  var valid_613432 = path.getOrDefault("EventDestinationName")
  valid_613432 = validateParameter(valid_613432, JString, required = true,
                                 default = nil)
  if valid_613432 != nil:
    section.add "EventDestinationName", valid_613432
  result.add "path", section
  section = newJObject()
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
  var valid_613433 = header.getOrDefault("X-Amz-Signature")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Signature", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Content-Sha256", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Date")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Date", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Credential")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Credential", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Security-Token")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Security-Token", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Algorithm")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Algorithm", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-SignedHeaders", valid_613439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613440: Call_DeleteConfigurationSetEventDestination_613428;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_613440.validator(path, query, header, formData, body)
  let scheme = call_613440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613440.url(scheme.get, call_613440.host, call_613440.base,
                         call_613440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613440, url, valid)

proc call*(call_613441: Call_DeleteConfigurationSetEventDestination_613428;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_613442 = newJObject()
  add(path_613442, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_613442, "EventDestinationName", newJString(EventDestinationName))
  result = call_613441.call(path_613442, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_613428(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_613429, base: "/",
    url: url_DeleteConfigurationSetEventDestination_613430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDedicatedIpPool_613443 = ref object of OpenApiRestCall_612658
proc url_DeleteDedicatedIpPool_613445(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "PoolName" in path, "`PoolName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ip-pools/"),
               (kind: VariableSegment, value: "PoolName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDedicatedIpPool_613444(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a dedicated IP pool.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   PoolName: JString (required)
  ##           : The name of a dedicated IP pool.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `PoolName` field"
  var valid_613446 = path.getOrDefault("PoolName")
  valid_613446 = validateParameter(valid_613446, JString, required = true,
                                 default = nil)
  if valid_613446 != nil:
    section.add "PoolName", valid_613446
  result.add "path", section
  section = newJObject()
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
  var valid_613447 = header.getOrDefault("X-Amz-Signature")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Signature", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Content-Sha256", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Date")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Date", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Credential")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Credential", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Security-Token")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Security-Token", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Algorithm")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Algorithm", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-SignedHeaders", valid_613453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613454: Call_DeleteDedicatedIpPool_613443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a dedicated IP pool.
  ## 
  let valid = call_613454.validator(path, query, header, formData, body)
  let scheme = call_613454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613454.url(scheme.get, call_613454.host, call_613454.base,
                         call_613454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613454, url, valid)

proc call*(call_613455: Call_DeleteDedicatedIpPool_613443; PoolName: string): Recallable =
  ## deleteDedicatedIpPool
  ## Delete a dedicated IP pool.
  ##   PoolName: string (required)
  ##           : The name of a dedicated IP pool.
  var path_613456 = newJObject()
  add(path_613456, "PoolName", newJString(PoolName))
  result = call_613455.call(path_613456, nil, nil, nil, nil)

var deleteDedicatedIpPool* = Call_DeleteDedicatedIpPool_613443(
    name: "deleteDedicatedIpPool", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools/{PoolName}",
    validator: validate_DeleteDedicatedIpPool_613444, base: "/",
    url: url_DeleteDedicatedIpPool_613445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailIdentity_613457 = ref object of OpenApiRestCall_612658
proc url_GetEmailIdentity_613459(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEmailIdentity_613458(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to retrieve details for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_613460 = path.getOrDefault("EmailIdentity")
  valid_613460 = validateParameter(valid_613460, JString, required = true,
                                 default = nil)
  if valid_613460 != nil:
    section.add "EmailIdentity", valid_613460
  result.add "path", section
  section = newJObject()
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
  var valid_613461 = header.getOrDefault("X-Amz-Signature")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Signature", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Content-Sha256", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Date")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Date", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Credential")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Credential", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Security-Token")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Security-Token", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Algorithm")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Algorithm", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-SignedHeaders", valid_613467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613468: Call_GetEmailIdentity_613457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  let valid = call_613468.validator(path, query, header, formData, body)
  let scheme = call_613468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613468.url(scheme.get, call_613468.host, call_613468.base,
                         call_613468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613468, url, valid)

proc call*(call_613469: Call_GetEmailIdentity_613457; EmailIdentity: string): Recallable =
  ## getEmailIdentity
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to retrieve details for.
  var path_613470 = newJObject()
  add(path_613470, "EmailIdentity", newJString(EmailIdentity))
  result = call_613469.call(path_613470, nil, nil, nil, nil)

var getEmailIdentity* = Call_GetEmailIdentity_613457(name: "getEmailIdentity",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_GetEmailIdentity_613458, base: "/",
    url: url_GetEmailIdentity_613459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailIdentity_613471 = ref object of OpenApiRestCall_612658
proc url_DeleteEmailIdentity_613473(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEmailIdentity_613472(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The identity (that is, the email address or domain) that you want to delete from your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_613474 = path.getOrDefault("EmailIdentity")
  valid_613474 = validateParameter(valid_613474, JString, required = true,
                                 default = nil)
  if valid_613474 != nil:
    section.add "EmailIdentity", valid_613474
  result.add "path", section
  section = newJObject()
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
  var valid_613475 = header.getOrDefault("X-Amz-Signature")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Signature", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Content-Sha256", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Date")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Date", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Credential")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Credential", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Security-Token")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Security-Token", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Algorithm")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Algorithm", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-SignedHeaders", valid_613481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613482: Call_DeleteEmailIdentity_613471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ## 
  let valid = call_613482.validator(path, query, header, formData, body)
  let scheme = call_613482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613482.url(scheme.get, call_613482.host, call_613482.base,
                         call_613482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613482, url, valid)

proc call*(call_613483: Call_DeleteEmailIdentity_613471; EmailIdentity: string): Recallable =
  ## deleteEmailIdentity
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ##   EmailIdentity: string (required)
  ##                : The identity (that is, the email address or domain) that you want to delete from your Amazon Pinpoint account.
  var path_613484 = newJObject()
  add(path_613484, "EmailIdentity", newJString(EmailIdentity))
  result = call_613483.call(path_613484, nil, nil, nil, nil)

var deleteEmailIdentity* = Call_DeleteEmailIdentity_613471(
    name: "deleteEmailIdentity", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_DeleteEmailIdentity_613472, base: "/",
    url: url_DeleteEmailIdentity_613473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_613485 = ref object of OpenApiRestCall_612658
proc url_GetAccount_613487(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccount_613486(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613488 = header.getOrDefault("X-Amz-Signature")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Signature", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Content-Sha256", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Date")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Date", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Credential")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Credential", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Security-Token")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Security-Token", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Algorithm")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Algorithm", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-SignedHeaders", valid_613494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613495: Call_GetAccount_613485; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_613495.validator(path, query, header, formData, body)
  let scheme = call_613495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613495.url(scheme.get, call_613495.host, call_613495.base,
                         call_613495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613495, url, valid)

proc call*(call_613496: Call_GetAccount_613485): Recallable =
  ## getAccount
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  result = call_613496.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_613485(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "email.amazonaws.com",
                                      route: "/v1/email/account",
                                      validator: validate_GetAccount_613486,
                                      base: "/", url: url_GetAccount_613487,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlacklistReports_613497 = ref object of OpenApiRestCall_612658
proc url_GetBlacklistReports_613499(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBlacklistReports_613498(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   BlacklistItemNames: JArray (required)
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon Pinpoint or Amazon SES.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `BlacklistItemNames` field"
  var valid_613500 = query.getOrDefault("BlacklistItemNames")
  valid_613500 = validateParameter(valid_613500, JArray, required = true, default = nil)
  if valid_613500 != nil:
    section.add "BlacklistItemNames", valid_613500
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
  var valid_613501 = header.getOrDefault("X-Amz-Signature")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Signature", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Content-Sha256", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Date")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Date", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Credential")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Credential", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Security-Token")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Security-Token", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Algorithm")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Algorithm", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-SignedHeaders", valid_613507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613508: Call_GetBlacklistReports_613497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ## 
  let valid = call_613508.validator(path, query, header, formData, body)
  let scheme = call_613508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613508.url(scheme.get, call_613508.host, call_613508.base,
                         call_613508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613508, url, valid)

proc call*(call_613509: Call_GetBlacklistReports_613497;
          BlacklistItemNames: JsonNode): Recallable =
  ## getBlacklistReports
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ##   BlacklistItemNames: JArray (required)
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon Pinpoint or Amazon SES.
  var query_613510 = newJObject()
  if BlacklistItemNames != nil:
    query_613510.add "BlacklistItemNames", BlacklistItemNames
  result = call_613509.call(nil, query_613510, nil, nil, nil)

var getBlacklistReports* = Call_GetBlacklistReports_613497(
    name: "getBlacklistReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/blacklist-report#BlacklistItemNames",
    validator: validate_GetBlacklistReports_613498, base: "/",
    url: url_GetBlacklistReports_613499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIp_613511 = ref object of OpenApiRestCall_612658
proc url_GetDedicatedIp_613513(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDedicatedIp_613512(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_613514 = path.getOrDefault("IP")
  valid_613514 = validateParameter(valid_613514, JString, required = true,
                                 default = nil)
  if valid_613514 != nil:
    section.add "IP", valid_613514
  result.add "path", section
  section = newJObject()
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
  var valid_613515 = header.getOrDefault("X-Amz-Signature")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Signature", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Content-Sha256", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Date")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Date", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Credential")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Credential", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Security-Token")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Security-Token", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Algorithm")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Algorithm", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-SignedHeaders", valid_613521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613522: Call_GetDedicatedIp_613511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  let valid = call_613522.validator(path, query, header, formData, body)
  let scheme = call_613522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613522.url(scheme.get, call_613522.host, call_613522.base,
                         call_613522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613522, url, valid)

proc call*(call_613523: Call_GetDedicatedIp_613511; IP: string): Recallable =
  ## getDedicatedIp
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  var path_613524 = newJObject()
  add(path_613524, "IP", newJString(IP))
  result = call_613523.call(path_613524, nil, nil, nil, nil)

var getDedicatedIp* = Call_GetDedicatedIp_613511(name: "getDedicatedIp",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips/{IP}", validator: validate_GetDedicatedIp_613512,
    base: "/", url: url_GetDedicatedIp_613513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIps_613525 = ref object of OpenApiRestCall_612658
proc url_GetDedicatedIps_613527(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDedicatedIps_613526(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   PoolName: JString
  ##           : The name of a dedicated IP pool.
  section = newJObject()
  var valid_613528 = query.getOrDefault("NextToken")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "NextToken", valid_613528
  var valid_613529 = query.getOrDefault("PageSize")
  valid_613529 = validateParameter(valid_613529, JInt, required = false, default = nil)
  if valid_613529 != nil:
    section.add "PageSize", valid_613529
  var valid_613530 = query.getOrDefault("PoolName")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "PoolName", valid_613530
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
  var valid_613531 = header.getOrDefault("X-Amz-Signature")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Signature", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Content-Sha256", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Date")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Date", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Credential")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Credential", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Security-Token")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Security-Token", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Algorithm")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Algorithm", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-SignedHeaders", valid_613537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613538: Call_GetDedicatedIps_613525; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_613538.validator(path, query, header, formData, body)
  let scheme = call_613538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613538.url(scheme.get, call_613538.host, call_613538.base,
                         call_613538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613538, url, valid)

proc call*(call_613539: Call_GetDedicatedIps_613525; NextToken: string = "";
          PageSize: int = 0; PoolName: string = ""): Recallable =
  ## getDedicatedIps
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   PoolName: string
  ##           : The name of a dedicated IP pool.
  var query_613540 = newJObject()
  add(query_613540, "NextToken", newJString(NextToken))
  add(query_613540, "PageSize", newJInt(PageSize))
  add(query_613540, "PoolName", newJString(PoolName))
  result = call_613539.call(nil, query_613540, nil, nil, nil)

var getDedicatedIps* = Call_GetDedicatedIps_613525(name: "getDedicatedIps",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips", validator: validate_GetDedicatedIps_613526,
    base: "/", url: url_GetDedicatedIps_613527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliverabilityDashboardOption_613553 = ref object of OpenApiRestCall_612658
proc url_PutDeliverabilityDashboardOption_613555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDeliverabilityDashboardOption_613554(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613556 = header.getOrDefault("X-Amz-Signature")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Signature", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Content-Sha256", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Date")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Date", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Credential")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Credential", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Security-Token")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Security-Token", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Algorithm")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Algorithm", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-SignedHeaders", valid_613562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613564: Call_PutDeliverabilityDashboardOption_613553;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_613564.validator(path, query, header, formData, body)
  let scheme = call_613564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613564.url(scheme.get, call_613564.host, call_613564.base,
                         call_613564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613564, url, valid)

proc call*(call_613565: Call_PutDeliverabilityDashboardOption_613553;
          body: JsonNode): Recallable =
  ## putDeliverabilityDashboardOption
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ##   body: JObject (required)
  var body_613566 = newJObject()
  if body != nil:
    body_613566 = body
  result = call_613565.call(nil, nil, nil, nil, body_613566)

var putDeliverabilityDashboardOption* = Call_PutDeliverabilityDashboardOption_613553(
    name: "putDeliverabilityDashboardOption", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_PutDeliverabilityDashboardOption_613554, base: "/",
    url: url_PutDeliverabilityDashboardOption_613555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityDashboardOptions_613541 = ref object of OpenApiRestCall_612658
proc url_GetDeliverabilityDashboardOptions_613543(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeliverabilityDashboardOptions_613542(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613544 = header.getOrDefault("X-Amz-Signature")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Signature", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Content-Sha256", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Date")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Date", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Credential")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Credential", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Security-Token")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Security-Token", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Algorithm")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Algorithm", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-SignedHeaders", valid_613550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613551: Call_GetDeliverabilityDashboardOptions_613541;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_613551.validator(path, query, header, formData, body)
  let scheme = call_613551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613551.url(scheme.get, call_613551.host, call_613551.base,
                         call_613551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613551, url, valid)

proc call*(call_613552: Call_GetDeliverabilityDashboardOptions_613541): Recallable =
  ## getDeliverabilityDashboardOptions
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  result = call_613552.call(nil, nil, nil, nil, nil)

var getDeliverabilityDashboardOptions* = Call_GetDeliverabilityDashboardOptions_613541(
    name: "getDeliverabilityDashboardOptions", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_GetDeliverabilityDashboardOptions_613542, base: "/",
    url: url_GetDeliverabilityDashboardOptions_613543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityTestReport_613567 = ref object of OpenApiRestCall_612658
proc url_GetDeliverabilityTestReport_613569(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ReportId" in path, "`ReportId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/test-reports/"),
               (kind: VariableSegment, value: "ReportId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeliverabilityTestReport_613568(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ReportId: JString (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ReportId` field"
  var valid_613570 = path.getOrDefault("ReportId")
  valid_613570 = validateParameter(valid_613570, JString, required = true,
                                 default = nil)
  if valid_613570 != nil:
    section.add "ReportId", valid_613570
  result.add "path", section
  section = newJObject()
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
  var valid_613571 = header.getOrDefault("X-Amz-Signature")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Signature", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Content-Sha256", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Date")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Date", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Credential")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Credential", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Security-Token")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Security-Token", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Algorithm")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Algorithm", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-SignedHeaders", valid_613577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613578: Call_GetDeliverabilityTestReport_613567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  let valid = call_613578.validator(path, query, header, formData, body)
  let scheme = call_613578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613578.url(scheme.get, call_613578.host, call_613578.base,
                         call_613578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613578, url, valid)

proc call*(call_613579: Call_GetDeliverabilityTestReport_613567; ReportId: string): Recallable =
  ## getDeliverabilityTestReport
  ## Retrieve the results of a predictive inbox placement test.
  ##   ReportId: string (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  var path_613580 = newJObject()
  add(path_613580, "ReportId", newJString(ReportId))
  result = call_613579.call(path_613580, nil, nil, nil, nil)

var getDeliverabilityTestReport* = Call_GetDeliverabilityTestReport_613567(
    name: "getDeliverabilityTestReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports/{ReportId}",
    validator: validate_GetDeliverabilityTestReport_613568, base: "/",
    url: url_GetDeliverabilityTestReport_613569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDeliverabilityCampaign_613581 = ref object of OpenApiRestCall_612658
proc url_GetDomainDeliverabilityCampaign_613583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CampaignId" in path, "`CampaignId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/campaigns/"),
               (kind: VariableSegment, value: "CampaignId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainDeliverabilityCampaign_613582(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CampaignId: JString (required)
  ##             : The unique identifier for the campaign. Amazon Pinpoint automatically generates and assigns this identifier to a campaign. This value is not the same as the campaign identifier that Amazon Pinpoint assigns to campaigns that you create and manage by using the Amazon Pinpoint API or the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CampaignId` field"
  var valid_613584 = path.getOrDefault("CampaignId")
  valid_613584 = validateParameter(valid_613584, JString, required = true,
                                 default = nil)
  if valid_613584 != nil:
    section.add "CampaignId", valid_613584
  result.add "path", section
  section = newJObject()
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
  var valid_613585 = header.getOrDefault("X-Amz-Signature")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Signature", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Content-Sha256", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Date")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Date", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Credential")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Credential", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Security-Token")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Security-Token", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Algorithm")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Algorithm", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-SignedHeaders", valid_613591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613592: Call_GetDomainDeliverabilityCampaign_613581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ## 
  let valid = call_613592.validator(path, query, header, formData, body)
  let scheme = call_613592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613592.url(scheme.get, call_613592.host, call_613592.base,
                         call_613592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613592, url, valid)

proc call*(call_613593: Call_GetDomainDeliverabilityCampaign_613581;
          CampaignId: string): Recallable =
  ## getDomainDeliverabilityCampaign
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ##   CampaignId: string (required)
  ##             : The unique identifier for the campaign. Amazon Pinpoint automatically generates and assigns this identifier to a campaign. This value is not the same as the campaign identifier that Amazon Pinpoint assigns to campaigns that you create and manage by using the Amazon Pinpoint API or the Amazon Pinpoint console.
  var path_613594 = newJObject()
  add(path_613594, "CampaignId", newJString(CampaignId))
  result = call_613593.call(path_613594, nil, nil, nil, nil)

var getDomainDeliverabilityCampaign* = Call_GetDomainDeliverabilityCampaign_613581(
    name: "getDomainDeliverabilityCampaign", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/campaigns/{CampaignId}",
    validator: validate_GetDomainDeliverabilityCampaign_613582, base: "/",
    url: url_GetDomainDeliverabilityCampaign_613583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainStatisticsReport_613595 = ref object of OpenApiRestCall_612658
proc url_GetDomainStatisticsReport_613597(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Domain" in path, "`Domain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/statistics-report/"),
               (kind: VariableSegment, value: "Domain"),
               (kind: ConstantSegment, value: "#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainStatisticsReport_613596(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Domain: JString (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Domain` field"
  var valid_613598 = path.getOrDefault("Domain")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = nil)
  if valid_613598 != nil:
    section.add "Domain", valid_613598
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: JString (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_613599 = query.getOrDefault("EndDate")
  valid_613599 = validateParameter(valid_613599, JString, required = true,
                                 default = nil)
  if valid_613599 != nil:
    section.add "EndDate", valid_613599
  var valid_613600 = query.getOrDefault("StartDate")
  valid_613600 = validateParameter(valid_613600, JString, required = true,
                                 default = nil)
  if valid_613600 != nil:
    section.add "StartDate", valid_613600
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
  var valid_613601 = header.getOrDefault("X-Amz-Signature")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Signature", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Content-Sha256", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Date")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Date", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Credential")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Credential", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Security-Token")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Security-Token", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Algorithm")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Algorithm", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-SignedHeaders", valid_613607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613608: Call_GetDomainStatisticsReport_613595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  let valid = call_613608.validator(path, query, header, formData, body)
  let scheme = call_613608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613608.url(scheme.get, call_613608.host, call_613608.base,
                         call_613608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613608, url, valid)

proc call*(call_613609: Call_GetDomainStatisticsReport_613595; EndDate: string;
          Domain: string; StartDate: string): Recallable =
  ## getDomainStatisticsReport
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ##   EndDate: string (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   Domain: string (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  ##   StartDate: string (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  var path_613610 = newJObject()
  var query_613611 = newJObject()
  add(query_613611, "EndDate", newJString(EndDate))
  add(path_613610, "Domain", newJString(Domain))
  add(query_613611, "StartDate", newJString(StartDate))
  result = call_613609.call(path_613610, query_613611, nil, nil, nil)

var getDomainStatisticsReport* = Call_GetDomainStatisticsReport_613595(
    name: "getDomainStatisticsReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/statistics-report/{Domain}#StartDate&EndDate",
    validator: validate_GetDomainStatisticsReport_613596, base: "/",
    url: url_GetDomainStatisticsReport_613597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeliverabilityTestReports_613612 = ref object of OpenApiRestCall_612658
proc url_ListDeliverabilityTestReports_613614(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeliverabilityTestReports_613613(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  ##   PageSize: JInt
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  section = newJObject()
  var valid_613615 = query.getOrDefault("NextToken")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "NextToken", valid_613615
  var valid_613616 = query.getOrDefault("PageSize")
  valid_613616 = validateParameter(valid_613616, JInt, required = false, default = nil)
  if valid_613616 != nil:
    section.add "PageSize", valid_613616
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
  var valid_613617 = header.getOrDefault("X-Amz-Signature")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Signature", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Content-Sha256", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Date")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Date", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Credential")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Credential", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Security-Token")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Security-Token", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Algorithm")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Algorithm", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-SignedHeaders", valid_613623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613624: Call_ListDeliverabilityTestReports_613612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  let valid = call_613624.validator(path, query, header, formData, body)
  let scheme = call_613624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613624.url(scheme.get, call_613624.host, call_613624.base,
                         call_613624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613624, url, valid)

proc call*(call_613625: Call_ListDeliverabilityTestReports_613612;
          NextToken: string = ""; PageSize: int = 0): Recallable =
  ## listDeliverabilityTestReports
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  var query_613626 = newJObject()
  add(query_613626, "NextToken", newJString(NextToken))
  add(query_613626, "PageSize", newJInt(PageSize))
  result = call_613625.call(nil, query_613626, nil, nil, nil)

var listDeliverabilityTestReports* = Call_ListDeliverabilityTestReports_613612(
    name: "listDeliverabilityTestReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports",
    validator: validate_ListDeliverabilityTestReports_613613, base: "/",
    url: url_ListDeliverabilityTestReports_613614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainDeliverabilityCampaigns_613627 = ref object of OpenApiRestCall_612658
proc url_ListDomainDeliverabilityCampaigns_613629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscribedDomain" in path,
        "`SubscribedDomain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/domains/"),
               (kind: VariableSegment, value: "SubscribedDomain"),
               (kind: ConstantSegment, value: "/campaigns#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDomainDeliverabilityCampaigns_613628(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscribedDomain: JString (required)
  ##                   : The domain to obtain deliverability data for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `SubscribedDomain` field"
  var valid_613630 = path.getOrDefault("SubscribedDomain")
  valid_613630 = validateParameter(valid_613630, JString, required = true,
                                 default = nil)
  if valid_613630 != nil:
    section.add "SubscribedDomain", valid_613630
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   NextToken: JString
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   PageSize: JInt
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   StartDate: JString (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_613631 = query.getOrDefault("EndDate")
  valid_613631 = validateParameter(valid_613631, JString, required = true,
                                 default = nil)
  if valid_613631 != nil:
    section.add "EndDate", valid_613631
  var valid_613632 = query.getOrDefault("NextToken")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "NextToken", valid_613632
  var valid_613633 = query.getOrDefault("PageSize")
  valid_613633 = validateParameter(valid_613633, JInt, required = false, default = nil)
  if valid_613633 != nil:
    section.add "PageSize", valid_613633
  var valid_613634 = query.getOrDefault("StartDate")
  valid_613634 = validateParameter(valid_613634, JString, required = true,
                                 default = nil)
  if valid_613634 != nil:
    section.add "StartDate", valid_613634
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
  var valid_613635 = header.getOrDefault("X-Amz-Signature")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Signature", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Content-Sha256", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Date")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Date", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Credential")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Credential", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Security-Token")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Security-Token", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Algorithm")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Algorithm", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-SignedHeaders", valid_613641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613642: Call_ListDomainDeliverabilityCampaigns_613627;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ## 
  let valid = call_613642.validator(path, query, header, formData, body)
  let scheme = call_613642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613642.url(scheme.get, call_613642.host, call_613642.base,
                         call_613642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613642, url, valid)

proc call*(call_613643: Call_ListDomainDeliverabilityCampaigns_613627;
          EndDate: string; SubscribedDomain: string; StartDate: string;
          NextToken: string = ""; PageSize: int = 0): Recallable =
  ## listDomainDeliverabilityCampaigns
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ##   EndDate: string (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   NextToken: string
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   SubscribedDomain: string (required)
  ##                   : The domain to obtain deliverability data for.
  ##   PageSize: int
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   StartDate: string (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  var path_613644 = newJObject()
  var query_613645 = newJObject()
  add(query_613645, "EndDate", newJString(EndDate))
  add(query_613645, "NextToken", newJString(NextToken))
  add(path_613644, "SubscribedDomain", newJString(SubscribedDomain))
  add(query_613645, "PageSize", newJInt(PageSize))
  add(query_613645, "StartDate", newJString(StartDate))
  result = call_613643.call(path_613644, query_613645, nil, nil, nil)

var listDomainDeliverabilityCampaigns* = Call_ListDomainDeliverabilityCampaigns_613627(
    name: "listDomainDeliverabilityCampaigns", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/domains/{SubscribedDomain}/campaigns#StartDate&EndDate",
    validator: validate_ListDomainDeliverabilityCampaigns_613628, base: "/",
    url: url_ListDomainDeliverabilityCampaigns_613629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613646 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613648(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_613647(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_613649 = query.getOrDefault("ResourceArn")
  valid_613649 = validateParameter(valid_613649, JString, required = true,
                                 default = nil)
  if valid_613649 != nil:
    section.add "ResourceArn", valid_613649
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
  var valid_613650 = header.getOrDefault("X-Amz-Signature")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Signature", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Content-Sha256", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Date")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Date", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Credential")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Credential", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Security-Token")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Security-Token", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Algorithm")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Algorithm", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-SignedHeaders", valid_613656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613657: Call_ListTagsForResource_613646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  let valid = call_613657.validator(path, query, header, formData, body)
  let scheme = call_613657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613657.url(scheme.get, call_613657.host, call_613657.base,
                         call_613657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613657, url, valid)

proc call*(call_613658: Call_ListTagsForResource_613646; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  var query_613659 = newJObject()
  add(query_613659, "ResourceArn", newJString(ResourceArn))
  result = call_613658.call(nil, query_613659, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613646(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/tags#ResourceArn",
    validator: validate_ListTagsForResource_613647, base: "/",
    url: url_ListTagsForResource_613648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountDedicatedIpWarmupAttributes_613660 = ref object of OpenApiRestCall_612658
proc url_PutAccountDedicatedIpWarmupAttributes_613662(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAccountDedicatedIpWarmupAttributes_613661(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613663 = header.getOrDefault("X-Amz-Signature")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Signature", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Content-Sha256", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Date")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Date", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Credential")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Credential", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Security-Token")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Security-Token", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Algorithm")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Algorithm", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-SignedHeaders", valid_613669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613671: Call_PutAccountDedicatedIpWarmupAttributes_613660;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ## 
  let valid = call_613671.validator(path, query, header, formData, body)
  let scheme = call_613671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613671.url(scheme.get, call_613671.host, call_613671.base,
                         call_613671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613671, url, valid)

proc call*(call_613672: Call_PutAccountDedicatedIpWarmupAttributes_613660;
          body: JsonNode): Recallable =
  ## putAccountDedicatedIpWarmupAttributes
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ##   body: JObject (required)
  var body_613673 = newJObject()
  if body != nil:
    body_613673 = body
  result = call_613672.call(nil, nil, nil, nil, body_613673)

var putAccountDedicatedIpWarmupAttributes* = Call_PutAccountDedicatedIpWarmupAttributes_613660(
    name: "putAccountDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/dedicated-ips/warmup",
    validator: validate_PutAccountDedicatedIpWarmupAttributes_613661, base: "/",
    url: url_PutAccountDedicatedIpWarmupAttributes_613662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSendingAttributes_613674 = ref object of OpenApiRestCall_612658
proc url_PutAccountSendingAttributes_613676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAccountSendingAttributes_613675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable the ability of your account to send email.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613677 = header.getOrDefault("X-Amz-Signature")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Signature", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Content-Sha256", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Date")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Date", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Credential")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Credential", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Security-Token")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Security-Token", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Algorithm")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Algorithm", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-SignedHeaders", valid_613683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613685: Call_PutAccountSendingAttributes_613674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enable or disable the ability of your account to send email.
  ## 
  let valid = call_613685.validator(path, query, header, formData, body)
  let scheme = call_613685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613685.url(scheme.get, call_613685.host, call_613685.base,
                         call_613685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613685, url, valid)

proc call*(call_613686: Call_PutAccountSendingAttributes_613674; body: JsonNode): Recallable =
  ## putAccountSendingAttributes
  ## Enable or disable the ability of your account to send email.
  ##   body: JObject (required)
  var body_613687 = newJObject()
  if body != nil:
    body_613687 = body
  result = call_613686.call(nil, nil, nil, nil, body_613687)

var putAccountSendingAttributes* = Call_PutAccountSendingAttributes_613674(
    name: "putAccountSendingAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/sending",
    validator: validate_PutAccountSendingAttributes_613675, base: "/",
    url: url_PutAccountSendingAttributes_613676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetDeliveryOptions_613688 = ref object of OpenApiRestCall_612658
proc url_PutConfigurationSetDeliveryOptions_613690(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/delivery-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetDeliveryOptions_613689(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613691 = path.getOrDefault("ConfigurationSetName")
  valid_613691 = validateParameter(valid_613691, JString, required = true,
                                 default = nil)
  if valid_613691 != nil:
    section.add "ConfigurationSetName", valid_613691
  result.add "path", section
  section = newJObject()
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
  var valid_613692 = header.getOrDefault("X-Amz-Signature")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Signature", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Content-Sha256", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Date")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Date", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Credential")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Credential", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Security-Token")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Security-Token", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Algorithm")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Algorithm", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-SignedHeaders", valid_613698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613700: Call_PutConfigurationSetDeliveryOptions_613688;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  let valid = call_613700.validator(path, query, header, formData, body)
  let scheme = call_613700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613700.url(scheme.get, call_613700.host, call_613700.base,
                         call_613700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613700, url, valid)

proc call*(call_613701: Call_PutConfigurationSetDeliveryOptions_613688;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetDeliveryOptions
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_613702 = newJObject()
  var body_613703 = newJObject()
  add(path_613702, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_613703 = body
  result = call_613701.call(path_613702, nil, nil, nil, body_613703)

var putConfigurationSetDeliveryOptions* = Call_PutConfigurationSetDeliveryOptions_613688(
    name: "putConfigurationSetDeliveryOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/delivery-options",
    validator: validate_PutConfigurationSetDeliveryOptions_613689, base: "/",
    url: url_PutConfigurationSetDeliveryOptions_613690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetReputationOptions_613704 = ref object of OpenApiRestCall_612658
proc url_PutConfigurationSetReputationOptions_613706(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/reputation-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetReputationOptions_613705(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613707 = path.getOrDefault("ConfigurationSetName")
  valid_613707 = validateParameter(valid_613707, JString, required = true,
                                 default = nil)
  if valid_613707 != nil:
    section.add "ConfigurationSetName", valid_613707
  result.add "path", section
  section = newJObject()
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
  var valid_613708 = header.getOrDefault("X-Amz-Signature")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Signature", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Content-Sha256", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Date")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Date", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Credential")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Credential", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Security-Token")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Security-Token", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Algorithm")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Algorithm", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-SignedHeaders", valid_613714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613716: Call_PutConfigurationSetReputationOptions_613704;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_613716.validator(path, query, header, formData, body)
  let scheme = call_613716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613716.url(scheme.get, call_613716.host, call_613716.base,
                         call_613716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613716, url, valid)

proc call*(call_613717: Call_PutConfigurationSetReputationOptions_613704;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetReputationOptions
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_613718 = newJObject()
  var body_613719 = newJObject()
  add(path_613718, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_613719 = body
  result = call_613717.call(path_613718, nil, nil, nil, body_613719)

var putConfigurationSetReputationOptions* = Call_PutConfigurationSetReputationOptions_613704(
    name: "putConfigurationSetReputationOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/reputation-options",
    validator: validate_PutConfigurationSetReputationOptions_613705, base: "/",
    url: url_PutConfigurationSetReputationOptions_613706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSendingOptions_613720 = ref object of OpenApiRestCall_612658
proc url_PutConfigurationSetSendingOptions_613722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/sending")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetSendingOptions_613721(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613723 = path.getOrDefault("ConfigurationSetName")
  valid_613723 = validateParameter(valid_613723, JString, required = true,
                                 default = nil)
  if valid_613723 != nil:
    section.add "ConfigurationSetName", valid_613723
  result.add "path", section
  section = newJObject()
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
  var valid_613724 = header.getOrDefault("X-Amz-Signature")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Signature", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Content-Sha256", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Date")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Date", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Credential")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Credential", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Security-Token")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Security-Token", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Algorithm")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Algorithm", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-SignedHeaders", valid_613730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613732: Call_PutConfigurationSetSendingOptions_613720;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_613732.validator(path, query, header, formData, body)
  let scheme = call_613732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613732.url(scheme.get, call_613732.host, call_613732.base,
                         call_613732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613732, url, valid)

proc call*(call_613733: Call_PutConfigurationSetSendingOptions_613720;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSendingOptions
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_613734 = newJObject()
  var body_613735 = newJObject()
  add(path_613734, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_613735 = body
  result = call_613733.call(path_613734, nil, nil, nil, body_613735)

var putConfigurationSetSendingOptions* = Call_PutConfigurationSetSendingOptions_613720(
    name: "putConfigurationSetSendingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}/sending",
    validator: validate_PutConfigurationSetSendingOptions_613721, base: "/",
    url: url_PutConfigurationSetSendingOptions_613722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetTrackingOptions_613736 = ref object of OpenApiRestCall_612658
proc url_PutConfigurationSetTrackingOptions_613738(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/tracking-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetTrackingOptions_613737(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_613739 = path.getOrDefault("ConfigurationSetName")
  valid_613739 = validateParameter(valid_613739, JString, required = true,
                                 default = nil)
  if valid_613739 != nil:
    section.add "ConfigurationSetName", valid_613739
  result.add "path", section
  section = newJObject()
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
  var valid_613740 = header.getOrDefault("X-Amz-Signature")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Signature", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Content-Sha256", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Date")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Date", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Credential")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Credential", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Security-Token")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Security-Token", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Algorithm")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Algorithm", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-SignedHeaders", valid_613746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613748: Call_PutConfigurationSetTrackingOptions_613736;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ## 
  let valid = call_613748.validator(path, query, header, formData, body)
  let scheme = call_613748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613748.url(scheme.get, call_613748.host, call_613748.base,
                         call_613748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613748, url, valid)

proc call*(call_613749: Call_PutConfigurationSetTrackingOptions_613736;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetTrackingOptions
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_613750 = newJObject()
  var body_613751 = newJObject()
  add(path_613750, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_613751 = body
  result = call_613749.call(path_613750, nil, nil, nil, body_613751)

var putConfigurationSetTrackingOptions* = Call_PutConfigurationSetTrackingOptions_613736(
    name: "putConfigurationSetTrackingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/tracking-options",
    validator: validate_PutConfigurationSetTrackingOptions_613737, base: "/",
    url: url_PutConfigurationSetTrackingOptions_613738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpInPool_613752 = ref object of OpenApiRestCall_612658
proc url_PutDedicatedIpInPool_613754(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/pool")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutDedicatedIpInPool_613753(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_613755 = path.getOrDefault("IP")
  valid_613755 = validateParameter(valid_613755, JString, required = true,
                                 default = nil)
  if valid_613755 != nil:
    section.add "IP", valid_613755
  result.add "path", section
  section = newJObject()
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
  var valid_613756 = header.getOrDefault("X-Amz-Signature")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Signature", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Content-Sha256", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Date")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Date", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Credential")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Credential", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Security-Token")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Security-Token", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Algorithm")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Algorithm", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-SignedHeaders", valid_613762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613764: Call_PutDedicatedIpInPool_613752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  let valid = call_613764.validator(path, query, header, formData, body)
  let scheme = call_613764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613764.url(scheme.get, call_613764.host, call_613764.base,
                         call_613764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613764, url, valid)

proc call*(call_613765: Call_PutDedicatedIpInPool_613752; IP: string; body: JsonNode): Recallable =
  ## putDedicatedIpInPool
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_613766 = newJObject()
  var body_613767 = newJObject()
  add(path_613766, "IP", newJString(IP))
  if body != nil:
    body_613767 = body
  result = call_613765.call(path_613766, nil, nil, nil, body_613767)

var putDedicatedIpInPool* = Call_PutDedicatedIpInPool_613752(
    name: "putDedicatedIpInPool", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/pool",
    validator: validate_PutDedicatedIpInPool_613753, base: "/",
    url: url_PutDedicatedIpInPool_613754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpWarmupAttributes_613768 = ref object of OpenApiRestCall_612658
proc url_PutDedicatedIpWarmupAttributes_613770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/warmup")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutDedicatedIpWarmupAttributes_613769(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_613771 = path.getOrDefault("IP")
  valid_613771 = validateParameter(valid_613771, JString, required = true,
                                 default = nil)
  if valid_613771 != nil:
    section.add "IP", valid_613771
  result.add "path", section
  section = newJObject()
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
  var valid_613772 = header.getOrDefault("X-Amz-Signature")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Signature", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Content-Sha256", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Date")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Date", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Credential")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Credential", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Security-Token")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Security-Token", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Algorithm")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Algorithm", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-SignedHeaders", valid_613778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613780: Call_PutDedicatedIpWarmupAttributes_613768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_613780.validator(path, query, header, formData, body)
  let scheme = call_613780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613780.url(scheme.get, call_613780.host, call_613780.base,
                         call_613780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613780, url, valid)

proc call*(call_613781: Call_PutDedicatedIpWarmupAttributes_613768; IP: string;
          body: JsonNode): Recallable =
  ## putDedicatedIpWarmupAttributes
  ## <p/>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_613782 = newJObject()
  var body_613783 = newJObject()
  add(path_613782, "IP", newJString(IP))
  if body != nil:
    body_613783 = body
  result = call_613781.call(path_613782, nil, nil, nil, body_613783)

var putDedicatedIpWarmupAttributes* = Call_PutDedicatedIpWarmupAttributes_613768(
    name: "putDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/warmup",
    validator: validate_PutDedicatedIpWarmupAttributes_613769, base: "/",
    url: url_PutDedicatedIpWarmupAttributes_613770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimAttributes_613784 = ref object of OpenApiRestCall_612658
proc url_PutEmailIdentityDkimAttributes_613786(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/dkim")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityDkimAttributes_613785(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Used to enable or disable DKIM authentication for an email identity.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to change the DKIM settings for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_613787 = path.getOrDefault("EmailIdentity")
  valid_613787 = validateParameter(valid_613787, JString, required = true,
                                 default = nil)
  if valid_613787 != nil:
    section.add "EmailIdentity", valid_613787
  result.add "path", section
  section = newJObject()
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
  var valid_613788 = header.getOrDefault("X-Amz-Signature")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Signature", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Content-Sha256", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Date")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Date", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Credential")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Credential", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Security-Token")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Security-Token", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Algorithm")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Algorithm", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-SignedHeaders", valid_613794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613796: Call_PutEmailIdentityDkimAttributes_613784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to enable or disable DKIM authentication for an email identity.
  ## 
  let valid = call_613796.validator(path, query, header, formData, body)
  let scheme = call_613796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613796.url(scheme.get, call_613796.host, call_613796.base,
                         call_613796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613796, url, valid)

proc call*(call_613797: Call_PutEmailIdentityDkimAttributes_613784;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityDkimAttributes
  ## Used to enable or disable DKIM authentication for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to change the DKIM settings for.
  ##   body: JObject (required)
  var path_613798 = newJObject()
  var body_613799 = newJObject()
  add(path_613798, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_613799 = body
  result = call_613797.call(path_613798, nil, nil, nil, body_613799)

var putEmailIdentityDkimAttributes* = Call_PutEmailIdentityDkimAttributes_613784(
    name: "putEmailIdentityDkimAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/dkim",
    validator: validate_PutEmailIdentityDkimAttributes_613785, base: "/",
    url: url_PutEmailIdentityDkimAttributes_613786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityFeedbackAttributes_613800 = ref object of OpenApiRestCall_612658
proc url_PutEmailIdentityFeedbackAttributes_613802(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/feedback")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityFeedbackAttributes_613801(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_613803 = path.getOrDefault("EmailIdentity")
  valid_613803 = validateParameter(valid_613803, JString, required = true,
                                 default = nil)
  if valid_613803 != nil:
    section.add "EmailIdentity", valid_613803
  result.add "path", section
  section = newJObject()
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
  var valid_613804 = header.getOrDefault("X-Amz-Signature")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Signature", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Content-Sha256", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Date")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Date", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-Credential")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-Credential", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-Security-Token")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Security-Token", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Algorithm")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Algorithm", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-SignedHeaders", valid_613810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613812: Call_PutEmailIdentityFeedbackAttributes_613800;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  let valid = call_613812.validator(path, query, header, formData, body)
  let scheme = call_613812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613812.url(scheme.get, call_613812.host, call_613812.base,
                         call_613812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613812, url, valid)

proc call*(call_613813: Call_PutEmailIdentityFeedbackAttributes_613800;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityFeedbackAttributes
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  ##   body: JObject (required)
  var path_613814 = newJObject()
  var body_613815 = newJObject()
  add(path_613814, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_613815 = body
  result = call_613813.call(path_613814, nil, nil, nil, body_613815)

var putEmailIdentityFeedbackAttributes* = Call_PutEmailIdentityFeedbackAttributes_613800(
    name: "putEmailIdentityFeedbackAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/feedback",
    validator: validate_PutEmailIdentityFeedbackAttributes_613801, base: "/",
    url: url_PutEmailIdentityFeedbackAttributes_613802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityMailFromAttributes_613816 = ref object of OpenApiRestCall_612658
proc url_PutEmailIdentityMailFromAttributes_613818(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/mail-from")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityMailFromAttributes_613817(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_613819 = path.getOrDefault("EmailIdentity")
  valid_613819 = validateParameter(valid_613819, JString, required = true,
                                 default = nil)
  if valid_613819 != nil:
    section.add "EmailIdentity", valid_613819
  result.add "path", section
  section = newJObject()
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
  var valid_613820 = header.getOrDefault("X-Amz-Signature")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Signature", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Content-Sha256", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-Date")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-Date", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-Credential")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-Credential", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Security-Token")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Security-Token", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Algorithm")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Algorithm", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-SignedHeaders", valid_613826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613828: Call_PutEmailIdentityMailFromAttributes_613816;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ## 
  let valid = call_613828.validator(path, query, header, formData, body)
  let scheme = call_613828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613828.url(scheme.get, call_613828.host, call_613828.base,
                         call_613828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613828, url, valid)

proc call*(call_613829: Call_PutEmailIdentityMailFromAttributes_613816;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityMailFromAttributes
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  ##   body: JObject (required)
  var path_613830 = newJObject()
  var body_613831 = newJObject()
  add(path_613830, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_613831 = body
  result = call_613829.call(path_613830, nil, nil, nil, body_613831)

var putEmailIdentityMailFromAttributes* = Call_PutEmailIdentityMailFromAttributes_613816(
    name: "putEmailIdentityMailFromAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/mail-from",
    validator: validate_PutEmailIdentityMailFromAttributes_613817, base: "/",
    url: url_PutEmailIdentityMailFromAttributes_613818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEmail_613832 = ref object of OpenApiRestCall_612658
proc url_SendEmail_613834(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendEmail_613833(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613835 = header.getOrDefault("X-Amz-Signature")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Signature", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Content-Sha256", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Date")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Date", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-Credential")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-Credential", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-Security-Token")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-Security-Token", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-Algorithm")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Algorithm", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-SignedHeaders", valid_613841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613843: Call_SendEmail_613832; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  let valid = call_613843.validator(path, query, header, formData, body)
  let scheme = call_613843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613843.url(scheme.get, call_613843.host, call_613843.base,
                         call_613843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613843, url, valid)

proc call*(call_613844: Call_SendEmail_613832; body: JsonNode): Recallable =
  ## sendEmail
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613845 = newJObject()
  if body != nil:
    body_613845 = body
  result = call_613844.call(nil, nil, nil, nil, body_613845)

var sendEmail* = Call_SendEmail_613832(name: "sendEmail", meth: HttpMethod.HttpPost,
                                    host: "email.amazonaws.com",
                                    route: "/v1/email/outbound-emails",
                                    validator: validate_SendEmail_613833,
                                    base: "/", url: url_SendEmail_613834,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613846 = ref object of OpenApiRestCall_612658
proc url_TagResource_613848(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_613847(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_613849 = header.getOrDefault("X-Amz-Signature")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Signature", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Content-Sha256", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Date")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Date", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Credential")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Credential", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-Security-Token")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-Security-Token", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Algorithm")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Algorithm", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-SignedHeaders", valid_613855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613857: Call_TagResource_613846; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  let valid = call_613857.validator(path, query, header, formData, body)
  let scheme = call_613857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613857.url(scheme.get, call_613857.host, call_613857.base,
                         call_613857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613857, url, valid)

proc call*(call_613858: Call_TagResource_613846; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   body: JObject (required)
  var body_613859 = newJObject()
  if body != nil:
    body_613859 = body
  result = call_613858.call(nil, nil, nil, nil, body_613859)

var tagResource* = Call_TagResource_613846(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "email.amazonaws.com",
                                        route: "/v1/email/tags",
                                        validator: validate_TagResource_613847,
                                        base: "/", url: url_TagResource_613848,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613860 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613862(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_613861(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TagKeys` field"
  var valid_613863 = query.getOrDefault("TagKeys")
  valid_613863 = validateParameter(valid_613863, JArray, required = true, default = nil)
  if valid_613863 != nil:
    section.add "TagKeys", valid_613863
  var valid_613864 = query.getOrDefault("ResourceArn")
  valid_613864 = validateParameter(valid_613864, JString, required = true,
                                 default = nil)
  if valid_613864 != nil:
    section.add "ResourceArn", valid_613864
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
  var valid_613865 = header.getOrDefault("X-Amz-Signature")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Signature", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Content-Sha256", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Date")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Date", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Credential")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Credential", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Security-Token")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Security-Token", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Algorithm")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Algorithm", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-SignedHeaders", valid_613871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613872: Call_UntagResource_613860; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  let valid = call_613872.validator(path, query, header, formData, body)
  let scheme = call_613872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613872.url(scheme.get, call_613872.host, call_613872.base,
                         call_613872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613872, url, valid)

proc call*(call_613873: Call_UntagResource_613860; TagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified resource.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  var query_613874 = newJObject()
  if TagKeys != nil:
    query_613874.add "TagKeys", TagKeys
  add(query_613874, "ResourceArn", newJString(ResourceArn))
  result = call_613873.call(nil, query_613874, nil, nil, nil)

var untagResource* = Call_UntagResource_613860(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "email.amazonaws.com",
    route: "/v1/email/tags#ResourceArn&TagKeys",
    validator: validate_UntagResource_613861, base: "/", url: url_UntagResource_613862,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
