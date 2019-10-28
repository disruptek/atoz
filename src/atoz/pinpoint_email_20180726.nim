
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateConfigurationSet_590960 = ref object of OpenApiRestCall_590364
proc url_CreateConfigurationSet_590962(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConfigurationSet_590961(path: JsonNode; query: JsonNode;
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
  var valid_590963 = header.getOrDefault("X-Amz-Signature")
  valid_590963 = validateParameter(valid_590963, JString, required = false,
                                 default = nil)
  if valid_590963 != nil:
    section.add "X-Amz-Signature", valid_590963
  var valid_590964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590964 = validateParameter(valid_590964, JString, required = false,
                                 default = nil)
  if valid_590964 != nil:
    section.add "X-Amz-Content-Sha256", valid_590964
  var valid_590965 = header.getOrDefault("X-Amz-Date")
  valid_590965 = validateParameter(valid_590965, JString, required = false,
                                 default = nil)
  if valid_590965 != nil:
    section.add "X-Amz-Date", valid_590965
  var valid_590966 = header.getOrDefault("X-Amz-Credential")
  valid_590966 = validateParameter(valid_590966, JString, required = false,
                                 default = nil)
  if valid_590966 != nil:
    section.add "X-Amz-Credential", valid_590966
  var valid_590967 = header.getOrDefault("X-Amz-Security-Token")
  valid_590967 = validateParameter(valid_590967, JString, required = false,
                                 default = nil)
  if valid_590967 != nil:
    section.add "X-Amz-Security-Token", valid_590967
  var valid_590968 = header.getOrDefault("X-Amz-Algorithm")
  valid_590968 = validateParameter(valid_590968, JString, required = false,
                                 default = nil)
  if valid_590968 != nil:
    section.add "X-Amz-Algorithm", valid_590968
  var valid_590969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590969 = validateParameter(valid_590969, JString, required = false,
                                 default = nil)
  if valid_590969 != nil:
    section.add "X-Amz-SignedHeaders", valid_590969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590971: Call_CreateConfigurationSet_590960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  let valid = call_590971.validator(path, query, header, formData, body)
  let scheme = call_590971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590971.url(scheme.get, call_590971.host, call_590971.base,
                         call_590971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590971, url, valid)

proc call*(call_590972: Call_CreateConfigurationSet_590960; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ##   body: JObject (required)
  var body_590973 = newJObject()
  if body != nil:
    body_590973 = body
  result = call_590972.call(nil, nil, nil, nil, body_590973)

var createConfigurationSet* = Call_CreateConfigurationSet_590960(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_CreateConfigurationSet_590961, base: "/",
    url: url_CreateConfigurationSet_590962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_590703 = ref object of OpenApiRestCall_590364
proc url_ListConfigurationSets_590705(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConfigurationSets_590704(path: JsonNode; query: JsonNode;
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
  var valid_590817 = query.getOrDefault("NextToken")
  valid_590817 = validateParameter(valid_590817, JString, required = false,
                                 default = nil)
  if valid_590817 != nil:
    section.add "NextToken", valid_590817
  var valid_590818 = query.getOrDefault("PageSize")
  valid_590818 = validateParameter(valid_590818, JInt, required = false, default = nil)
  if valid_590818 != nil:
    section.add "PageSize", valid_590818
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
  var valid_590819 = header.getOrDefault("X-Amz-Signature")
  valid_590819 = validateParameter(valid_590819, JString, required = false,
                                 default = nil)
  if valid_590819 != nil:
    section.add "X-Amz-Signature", valid_590819
  var valid_590820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590820 = validateParameter(valid_590820, JString, required = false,
                                 default = nil)
  if valid_590820 != nil:
    section.add "X-Amz-Content-Sha256", valid_590820
  var valid_590821 = header.getOrDefault("X-Amz-Date")
  valid_590821 = validateParameter(valid_590821, JString, required = false,
                                 default = nil)
  if valid_590821 != nil:
    section.add "X-Amz-Date", valid_590821
  var valid_590822 = header.getOrDefault("X-Amz-Credential")
  valid_590822 = validateParameter(valid_590822, JString, required = false,
                                 default = nil)
  if valid_590822 != nil:
    section.add "X-Amz-Credential", valid_590822
  var valid_590823 = header.getOrDefault("X-Amz-Security-Token")
  valid_590823 = validateParameter(valid_590823, JString, required = false,
                                 default = nil)
  if valid_590823 != nil:
    section.add "X-Amz-Security-Token", valid_590823
  var valid_590824 = header.getOrDefault("X-Amz-Algorithm")
  valid_590824 = validateParameter(valid_590824, JString, required = false,
                                 default = nil)
  if valid_590824 != nil:
    section.add "X-Amz-Algorithm", valid_590824
  var valid_590825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590825 = validateParameter(valid_590825, JString, required = false,
                                 default = nil)
  if valid_590825 != nil:
    section.add "X-Amz-SignedHeaders", valid_590825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590848: Call_ListConfigurationSets_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_590848.validator(path, query, header, formData, body)
  let scheme = call_590848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590848.url(scheme.get, call_590848.host, call_590848.base,
                         call_590848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590848, url, valid)

proc call*(call_590919: Call_ListConfigurationSets_590703; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listConfigurationSets
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  var query_590920 = newJObject()
  add(query_590920, "NextToken", newJString(NextToken))
  add(query_590920, "PageSize", newJInt(PageSize))
  result = call_590919.call(nil, query_590920, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_590703(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_ListConfigurationSets_590704, base: "/",
    url: url_ListConfigurationSets_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_591002 = ref object of OpenApiRestCall_590364
proc url_CreateConfigurationSetEventDestination_591004(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_591003(path: JsonNode;
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
  var valid_591005 = path.getOrDefault("ConfigurationSetName")
  valid_591005 = validateParameter(valid_591005, JString, required = true,
                                 default = nil)
  if valid_591005 != nil:
    section.add "ConfigurationSetName", valid_591005
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
  var valid_591006 = header.getOrDefault("X-Amz-Signature")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Signature", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Content-Sha256", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Date")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Date", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Credential")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Credential", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Security-Token")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Security-Token", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Algorithm")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Algorithm", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-SignedHeaders", valid_591012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591014: Call_CreateConfigurationSetEventDestination_591002;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  let valid = call_591014.validator(path, query, header, formData, body)
  let scheme = call_591014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591014.url(scheme.get, call_591014.host, call_591014.base,
                         call_591014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591014, url, valid)

proc call*(call_591015: Call_CreateConfigurationSetEventDestination_591002;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_591016 = newJObject()
  var body_591017 = newJObject()
  add(path_591016, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_591017 = body
  result = call_591015.call(path_591016, nil, nil, nil, body_591017)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_591002(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_591003, base: "/",
    url: url_CreateConfigurationSetEventDestination_591004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_590974 = ref object of OpenApiRestCall_590364
proc url_GetConfigurationSetEventDestinations_590976(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_590975(path: JsonNode;
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
  var valid_590991 = path.getOrDefault("ConfigurationSetName")
  valid_590991 = validateParameter(valid_590991, JString, required = true,
                                 default = nil)
  if valid_590991 != nil:
    section.add "ConfigurationSetName", valid_590991
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
  var valid_590992 = header.getOrDefault("X-Amz-Signature")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Signature", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Content-Sha256", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Date")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Date", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Credential")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Credential", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Security-Token")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Security-Token", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-Algorithm")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-Algorithm", valid_590997
  var valid_590998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590998 = validateParameter(valid_590998, JString, required = false,
                                 default = nil)
  if valid_590998 != nil:
    section.add "X-Amz-SignedHeaders", valid_590998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590999: Call_GetConfigurationSetEventDestinations_590974;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_590999.validator(path, query, header, formData, body)
  let scheme = call_590999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590999.url(scheme.get, call_590999.host, call_590999.base,
                         call_590999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590999, url, valid)

proc call*(call_591000: Call_GetConfigurationSetEventDestinations_590974;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_591001 = newJObject()
  add(path_591001, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_591000.call(path_591001, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_590974(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_590975, base: "/",
    url: url_GetConfigurationSetEventDestinations_590976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDedicatedIpPool_591033 = ref object of OpenApiRestCall_590364
proc url_CreateDedicatedIpPool_591035(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDedicatedIpPool_591034(path: JsonNode; query: JsonNode;
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
  var valid_591036 = header.getOrDefault("X-Amz-Signature")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Signature", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Content-Sha256", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Date")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Date", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Credential")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Credential", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Security-Token")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Security-Token", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Algorithm")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Algorithm", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-SignedHeaders", valid_591042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591044: Call_CreateDedicatedIpPool_591033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ## 
  let valid = call_591044.validator(path, query, header, formData, body)
  let scheme = call_591044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591044.url(scheme.get, call_591044.host, call_591044.base,
                         call_591044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591044, url, valid)

proc call*(call_591045: Call_CreateDedicatedIpPool_591033; body: JsonNode): Recallable =
  ## createDedicatedIpPool
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ##   body: JObject (required)
  var body_591046 = newJObject()
  if body != nil:
    body_591046 = body
  result = call_591045.call(nil, nil, nil, nil, body_591046)

var createDedicatedIpPool* = Call_CreateDedicatedIpPool_591033(
    name: "createDedicatedIpPool", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_CreateDedicatedIpPool_591034, base: "/",
    url: url_CreateDedicatedIpPool_591035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDedicatedIpPools_591018 = ref object of OpenApiRestCall_590364
proc url_ListDedicatedIpPools_591020(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDedicatedIpPools_591019(path: JsonNode; query: JsonNode;
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
  var valid_591021 = query.getOrDefault("NextToken")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "NextToken", valid_591021
  var valid_591022 = query.getOrDefault("PageSize")
  valid_591022 = validateParameter(valid_591022, JInt, required = false, default = nil)
  if valid_591022 != nil:
    section.add "PageSize", valid_591022
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
  var valid_591023 = header.getOrDefault("X-Amz-Signature")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Signature", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Content-Sha256", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Date")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Date", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Credential")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Credential", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-Security-Token")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-Security-Token", valid_591027
  var valid_591028 = header.getOrDefault("X-Amz-Algorithm")
  valid_591028 = validateParameter(valid_591028, JString, required = false,
                                 default = nil)
  if valid_591028 != nil:
    section.add "X-Amz-Algorithm", valid_591028
  var valid_591029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591029 = validateParameter(valid_591029, JString, required = false,
                                 default = nil)
  if valid_591029 != nil:
    section.add "X-Amz-SignedHeaders", valid_591029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591030: Call_ListDedicatedIpPools_591018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_591030.validator(path, query, header, formData, body)
  let scheme = call_591030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591030.url(scheme.get, call_591030.host, call_591030.base,
                         call_591030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591030, url, valid)

proc call*(call_591031: Call_ListDedicatedIpPools_591018; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listDedicatedIpPools
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  var query_591032 = newJObject()
  add(query_591032, "NextToken", newJString(NextToken))
  add(query_591032, "PageSize", newJInt(PageSize))
  result = call_591031.call(nil, query_591032, nil, nil, nil)

var listDedicatedIpPools* = Call_ListDedicatedIpPools_591018(
    name: "listDedicatedIpPools", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_ListDedicatedIpPools_591019, base: "/",
    url: url_ListDedicatedIpPools_591020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeliverabilityTestReport_591047 = ref object of OpenApiRestCall_590364
proc url_CreateDeliverabilityTestReport_591049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeliverabilityTestReport_591048(path: JsonNode;
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
  var valid_591050 = header.getOrDefault("X-Amz-Signature")
  valid_591050 = validateParameter(valid_591050, JString, required = false,
                                 default = nil)
  if valid_591050 != nil:
    section.add "X-Amz-Signature", valid_591050
  var valid_591051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Content-Sha256", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Date")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Date", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Credential")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Credential", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Security-Token")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Security-Token", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Algorithm")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Algorithm", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-SignedHeaders", valid_591056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591058: Call_CreateDeliverabilityTestReport_591047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  let valid = call_591058.validator(path, query, header, formData, body)
  let scheme = call_591058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591058.url(scheme.get, call_591058.host, call_591058.base,
                         call_591058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591058, url, valid)

proc call*(call_591059: Call_CreateDeliverabilityTestReport_591047; body: JsonNode): Recallable =
  ## createDeliverabilityTestReport
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ##   body: JObject (required)
  var body_591060 = newJObject()
  if body != nil:
    body_591060 = body
  result = call_591059.call(nil, nil, nil, nil, body_591060)

var createDeliverabilityTestReport* = Call_CreateDeliverabilityTestReport_591047(
    name: "createDeliverabilityTestReport", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/test",
    validator: validate_CreateDeliverabilityTestReport_591048, base: "/",
    url: url_CreateDeliverabilityTestReport_591049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailIdentity_591076 = ref object of OpenApiRestCall_590364
proc url_CreateEmailIdentity_591078(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEmailIdentity_591077(path: JsonNode; query: JsonNode;
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
  var valid_591079 = header.getOrDefault("X-Amz-Signature")
  valid_591079 = validateParameter(valid_591079, JString, required = false,
                                 default = nil)
  if valid_591079 != nil:
    section.add "X-Amz-Signature", valid_591079
  var valid_591080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591080 = validateParameter(valid_591080, JString, required = false,
                                 default = nil)
  if valid_591080 != nil:
    section.add "X-Amz-Content-Sha256", valid_591080
  var valid_591081 = header.getOrDefault("X-Amz-Date")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Date", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Credential")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Credential", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Security-Token")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Security-Token", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Algorithm")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Algorithm", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-SignedHeaders", valid_591085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591087: Call_CreateEmailIdentity_591076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ## 
  let valid = call_591087.validator(path, query, header, formData, body)
  let scheme = call_591087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591087.url(scheme.get, call_591087.host, call_591087.base,
                         call_591087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591087, url, valid)

proc call*(call_591088: Call_CreateEmailIdentity_591076; body: JsonNode): Recallable =
  ## createEmailIdentity
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ##   body: JObject (required)
  var body_591089 = newJObject()
  if body != nil:
    body_591089 = body
  result = call_591088.call(nil, nil, nil, nil, body_591089)

var createEmailIdentity* = Call_CreateEmailIdentity_591076(
    name: "createEmailIdentity", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_CreateEmailIdentity_591077, base: "/",
    url: url_CreateEmailIdentity_591078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEmailIdentities_591061 = ref object of OpenApiRestCall_590364
proc url_ListEmailIdentities_591063(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEmailIdentities_591062(path: JsonNode; query: JsonNode;
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
  var valid_591064 = query.getOrDefault("NextToken")
  valid_591064 = validateParameter(valid_591064, JString, required = false,
                                 default = nil)
  if valid_591064 != nil:
    section.add "NextToken", valid_591064
  var valid_591065 = query.getOrDefault("PageSize")
  valid_591065 = validateParameter(valid_591065, JInt, required = false, default = nil)
  if valid_591065 != nil:
    section.add "PageSize", valid_591065
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
  var valid_591066 = header.getOrDefault("X-Amz-Signature")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Signature", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Content-Sha256", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Date")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Date", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Credential")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Credential", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Security-Token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Security-Token", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Algorithm")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Algorithm", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-SignedHeaders", valid_591072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591073: Call_ListEmailIdentities_591061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ## 
  let valid = call_591073.validator(path, query, header, formData, body)
  let scheme = call_591073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591073.url(scheme.get, call_591073.host, call_591073.base,
                         call_591073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591073, url, valid)

proc call*(call_591074: Call_ListEmailIdentities_591061; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listEmailIdentities
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  var query_591075 = newJObject()
  add(query_591075, "NextToken", newJString(NextToken))
  add(query_591075, "PageSize", newJInt(PageSize))
  result = call_591074.call(nil, query_591075, nil, nil, nil)

var listEmailIdentities* = Call_ListEmailIdentities_591061(
    name: "listEmailIdentities", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_ListEmailIdentities_591062, base: "/",
    url: url_ListEmailIdentities_591063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSet_591090 = ref object of OpenApiRestCall_590364
proc url_GetConfigurationSet_591092(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetConfigurationSet_591091(path: JsonNode; query: JsonNode;
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
  var valid_591093 = path.getOrDefault("ConfigurationSetName")
  valid_591093 = validateParameter(valid_591093, JString, required = true,
                                 default = nil)
  if valid_591093 != nil:
    section.add "ConfigurationSetName", valid_591093
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
  var valid_591094 = header.getOrDefault("X-Amz-Signature")
  valid_591094 = validateParameter(valid_591094, JString, required = false,
                                 default = nil)
  if valid_591094 != nil:
    section.add "X-Amz-Signature", valid_591094
  var valid_591095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591095 = validateParameter(valid_591095, JString, required = false,
                                 default = nil)
  if valid_591095 != nil:
    section.add "X-Amz-Content-Sha256", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Date")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Date", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Credential")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Credential", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Security-Token")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Security-Token", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Algorithm")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Algorithm", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-SignedHeaders", valid_591100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591101: Call_GetConfigurationSet_591090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_591101.validator(path, query, header, formData, body)
  let scheme = call_591101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591101.url(scheme.get, call_591101.host, call_591101.base,
                         call_591101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591101, url, valid)

proc call*(call_591102: Call_GetConfigurationSet_591090;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSet
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_591103 = newJObject()
  add(path_591103, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_591102.call(path_591103, nil, nil, nil, nil)

var getConfigurationSet* = Call_GetConfigurationSet_591090(
    name: "getConfigurationSet", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_GetConfigurationSet_591091, base: "/",
    url: url_GetConfigurationSet_591092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_591104 = ref object of OpenApiRestCall_590364
proc url_DeleteConfigurationSet_591106(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_591105(path: JsonNode; query: JsonNode;
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
  var valid_591107 = path.getOrDefault("ConfigurationSetName")
  valid_591107 = validateParameter(valid_591107, JString, required = true,
                                 default = nil)
  if valid_591107 != nil:
    section.add "ConfigurationSetName", valid_591107
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
  var valid_591108 = header.getOrDefault("X-Amz-Signature")
  valid_591108 = validateParameter(valid_591108, JString, required = false,
                                 default = nil)
  if valid_591108 != nil:
    section.add "X-Amz-Signature", valid_591108
  var valid_591109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591109 = validateParameter(valid_591109, JString, required = false,
                                 default = nil)
  if valid_591109 != nil:
    section.add "X-Amz-Content-Sha256", valid_591109
  var valid_591110 = header.getOrDefault("X-Amz-Date")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-Date", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Credential")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Credential", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Security-Token")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Security-Token", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Algorithm")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Algorithm", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-SignedHeaders", valid_591114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591115: Call_DeleteConfigurationSet_591104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_591115.validator(path, query, header, formData, body)
  let scheme = call_591115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591115.url(scheme.get, call_591115.host, call_591115.base,
                         call_591115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591115, url, valid)

proc call*(call_591116: Call_DeleteConfigurationSet_591104;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_591117 = newJObject()
  add(path_591117, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_591116.call(path_591117, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_591104(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_591105, base: "/",
    url: url_DeleteConfigurationSet_591106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_591118 = ref object of OpenApiRestCall_590364
proc url_UpdateConfigurationSetEventDestination_591120(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_UpdateConfigurationSetEventDestination_591119(path: JsonNode;
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
  var valid_591121 = path.getOrDefault("ConfigurationSetName")
  valid_591121 = validateParameter(valid_591121, JString, required = true,
                                 default = nil)
  if valid_591121 != nil:
    section.add "ConfigurationSetName", valid_591121
  var valid_591122 = path.getOrDefault("EventDestinationName")
  valid_591122 = validateParameter(valid_591122, JString, required = true,
                                 default = nil)
  if valid_591122 != nil:
    section.add "EventDestinationName", valid_591122
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
  var valid_591123 = header.getOrDefault("X-Amz-Signature")
  valid_591123 = validateParameter(valid_591123, JString, required = false,
                                 default = nil)
  if valid_591123 != nil:
    section.add "X-Amz-Signature", valid_591123
  var valid_591124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591124 = validateParameter(valid_591124, JString, required = false,
                                 default = nil)
  if valid_591124 != nil:
    section.add "X-Amz-Content-Sha256", valid_591124
  var valid_591125 = header.getOrDefault("X-Amz-Date")
  valid_591125 = validateParameter(valid_591125, JString, required = false,
                                 default = nil)
  if valid_591125 != nil:
    section.add "X-Amz-Date", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Credential")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Credential", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Security-Token")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Security-Token", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Algorithm")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Algorithm", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-SignedHeaders", valid_591129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591131: Call_UpdateConfigurationSetEventDestination_591118;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_591131.validator(path, query, header, formData, body)
  let scheme = call_591131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591131.url(scheme.get, call_591131.host, call_591131.base,
                         call_591131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591131, url, valid)

proc call*(call_591132: Call_UpdateConfigurationSetEventDestination_591118;
          ConfigurationSetName: string; EventDestinationName: string; body: JsonNode): Recallable =
  ## updateConfigurationSetEventDestination
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   body: JObject (required)
  var path_591133 = newJObject()
  var body_591134 = newJObject()
  add(path_591133, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_591133, "EventDestinationName", newJString(EventDestinationName))
  if body != nil:
    body_591134 = body
  result = call_591132.call(path_591133, nil, nil, nil, body_591134)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_591118(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_591119, base: "/",
    url: url_UpdateConfigurationSetEventDestination_591120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_591135 = ref object of OpenApiRestCall_590364
proc url_DeleteConfigurationSetEventDestination_591137(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_DeleteConfigurationSetEventDestination_591136(path: JsonNode;
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
  var valid_591138 = path.getOrDefault("ConfigurationSetName")
  valid_591138 = validateParameter(valid_591138, JString, required = true,
                                 default = nil)
  if valid_591138 != nil:
    section.add "ConfigurationSetName", valid_591138
  var valid_591139 = path.getOrDefault("EventDestinationName")
  valid_591139 = validateParameter(valid_591139, JString, required = true,
                                 default = nil)
  if valid_591139 != nil:
    section.add "EventDestinationName", valid_591139
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
  var valid_591140 = header.getOrDefault("X-Amz-Signature")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Signature", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Content-Sha256", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Date")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Date", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Credential")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Credential", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Security-Token")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Security-Token", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Algorithm")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Algorithm", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-SignedHeaders", valid_591146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591147: Call_DeleteConfigurationSetEventDestination_591135;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_591147.validator(path, query, header, formData, body)
  let scheme = call_591147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591147.url(scheme.get, call_591147.host, call_591147.base,
                         call_591147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591147, url, valid)

proc call*(call_591148: Call_DeleteConfigurationSetEventDestination_591135;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_591149 = newJObject()
  add(path_591149, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_591149, "EventDestinationName", newJString(EventDestinationName))
  result = call_591148.call(path_591149, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_591135(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_591136, base: "/",
    url: url_DeleteConfigurationSetEventDestination_591137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDedicatedIpPool_591150 = ref object of OpenApiRestCall_590364
proc url_DeleteDedicatedIpPool_591152(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteDedicatedIpPool_591151(path: JsonNode; query: JsonNode;
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
  var valid_591153 = path.getOrDefault("PoolName")
  valid_591153 = validateParameter(valid_591153, JString, required = true,
                                 default = nil)
  if valid_591153 != nil:
    section.add "PoolName", valid_591153
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
  var valid_591154 = header.getOrDefault("X-Amz-Signature")
  valid_591154 = validateParameter(valid_591154, JString, required = false,
                                 default = nil)
  if valid_591154 != nil:
    section.add "X-Amz-Signature", valid_591154
  var valid_591155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "X-Amz-Content-Sha256", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Date")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Date", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Credential")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Credential", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Security-Token")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Security-Token", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Algorithm")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Algorithm", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-SignedHeaders", valid_591160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591161: Call_DeleteDedicatedIpPool_591150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a dedicated IP pool.
  ## 
  let valid = call_591161.validator(path, query, header, formData, body)
  let scheme = call_591161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591161.url(scheme.get, call_591161.host, call_591161.base,
                         call_591161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591161, url, valid)

proc call*(call_591162: Call_DeleteDedicatedIpPool_591150; PoolName: string): Recallable =
  ## deleteDedicatedIpPool
  ## Delete a dedicated IP pool.
  ##   PoolName: string (required)
  ##           : The name of a dedicated IP pool.
  var path_591163 = newJObject()
  add(path_591163, "PoolName", newJString(PoolName))
  result = call_591162.call(path_591163, nil, nil, nil, nil)

var deleteDedicatedIpPool* = Call_DeleteDedicatedIpPool_591150(
    name: "deleteDedicatedIpPool", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools/{PoolName}",
    validator: validate_DeleteDedicatedIpPool_591151, base: "/",
    url: url_DeleteDedicatedIpPool_591152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailIdentity_591164 = ref object of OpenApiRestCall_590364
proc url_GetEmailIdentity_591166(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetEmailIdentity_591165(path: JsonNode; query: JsonNode;
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
  var valid_591167 = path.getOrDefault("EmailIdentity")
  valid_591167 = validateParameter(valid_591167, JString, required = true,
                                 default = nil)
  if valid_591167 != nil:
    section.add "EmailIdentity", valid_591167
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
  var valid_591168 = header.getOrDefault("X-Amz-Signature")
  valid_591168 = validateParameter(valid_591168, JString, required = false,
                                 default = nil)
  if valid_591168 != nil:
    section.add "X-Amz-Signature", valid_591168
  var valid_591169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591169 = validateParameter(valid_591169, JString, required = false,
                                 default = nil)
  if valid_591169 != nil:
    section.add "X-Amz-Content-Sha256", valid_591169
  var valid_591170 = header.getOrDefault("X-Amz-Date")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "X-Amz-Date", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Credential")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Credential", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Security-Token")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Security-Token", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Algorithm")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Algorithm", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-SignedHeaders", valid_591174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591175: Call_GetEmailIdentity_591164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  let valid = call_591175.validator(path, query, header, formData, body)
  let scheme = call_591175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591175.url(scheme.get, call_591175.host, call_591175.base,
                         call_591175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591175, url, valid)

proc call*(call_591176: Call_GetEmailIdentity_591164; EmailIdentity: string): Recallable =
  ## getEmailIdentity
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to retrieve details for.
  var path_591177 = newJObject()
  add(path_591177, "EmailIdentity", newJString(EmailIdentity))
  result = call_591176.call(path_591177, nil, nil, nil, nil)

var getEmailIdentity* = Call_GetEmailIdentity_591164(name: "getEmailIdentity",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_GetEmailIdentity_591165, base: "/",
    url: url_GetEmailIdentity_591166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailIdentity_591178 = ref object of OpenApiRestCall_590364
proc url_DeleteEmailIdentity_591180(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteEmailIdentity_591179(path: JsonNode; query: JsonNode;
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
  var valid_591181 = path.getOrDefault("EmailIdentity")
  valid_591181 = validateParameter(valid_591181, JString, required = true,
                                 default = nil)
  if valid_591181 != nil:
    section.add "EmailIdentity", valid_591181
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
  var valid_591182 = header.getOrDefault("X-Amz-Signature")
  valid_591182 = validateParameter(valid_591182, JString, required = false,
                                 default = nil)
  if valid_591182 != nil:
    section.add "X-Amz-Signature", valid_591182
  var valid_591183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591183 = validateParameter(valid_591183, JString, required = false,
                                 default = nil)
  if valid_591183 != nil:
    section.add "X-Amz-Content-Sha256", valid_591183
  var valid_591184 = header.getOrDefault("X-Amz-Date")
  valid_591184 = validateParameter(valid_591184, JString, required = false,
                                 default = nil)
  if valid_591184 != nil:
    section.add "X-Amz-Date", valid_591184
  var valid_591185 = header.getOrDefault("X-Amz-Credential")
  valid_591185 = validateParameter(valid_591185, JString, required = false,
                                 default = nil)
  if valid_591185 != nil:
    section.add "X-Amz-Credential", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Security-Token")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Security-Token", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Algorithm")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Algorithm", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-SignedHeaders", valid_591188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591189: Call_DeleteEmailIdentity_591178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ## 
  let valid = call_591189.validator(path, query, header, formData, body)
  let scheme = call_591189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591189.url(scheme.get, call_591189.host, call_591189.base,
                         call_591189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591189, url, valid)

proc call*(call_591190: Call_DeleteEmailIdentity_591178; EmailIdentity: string): Recallable =
  ## deleteEmailIdentity
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ##   EmailIdentity: string (required)
  ##                : The identity (that is, the email address or domain) that you want to delete from your Amazon Pinpoint account.
  var path_591191 = newJObject()
  add(path_591191, "EmailIdentity", newJString(EmailIdentity))
  result = call_591190.call(path_591191, nil, nil, nil, nil)

var deleteEmailIdentity* = Call_DeleteEmailIdentity_591178(
    name: "deleteEmailIdentity", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_DeleteEmailIdentity_591179, base: "/",
    url: url_DeleteEmailIdentity_591180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_591192 = ref object of OpenApiRestCall_590364
proc url_GetAccount_591194(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAccount_591193(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591195 = header.getOrDefault("X-Amz-Signature")
  valid_591195 = validateParameter(valid_591195, JString, required = false,
                                 default = nil)
  if valid_591195 != nil:
    section.add "X-Amz-Signature", valid_591195
  var valid_591196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591196 = validateParameter(valid_591196, JString, required = false,
                                 default = nil)
  if valid_591196 != nil:
    section.add "X-Amz-Content-Sha256", valid_591196
  var valid_591197 = header.getOrDefault("X-Amz-Date")
  valid_591197 = validateParameter(valid_591197, JString, required = false,
                                 default = nil)
  if valid_591197 != nil:
    section.add "X-Amz-Date", valid_591197
  var valid_591198 = header.getOrDefault("X-Amz-Credential")
  valid_591198 = validateParameter(valid_591198, JString, required = false,
                                 default = nil)
  if valid_591198 != nil:
    section.add "X-Amz-Credential", valid_591198
  var valid_591199 = header.getOrDefault("X-Amz-Security-Token")
  valid_591199 = validateParameter(valid_591199, JString, required = false,
                                 default = nil)
  if valid_591199 != nil:
    section.add "X-Amz-Security-Token", valid_591199
  var valid_591200 = header.getOrDefault("X-Amz-Algorithm")
  valid_591200 = validateParameter(valid_591200, JString, required = false,
                                 default = nil)
  if valid_591200 != nil:
    section.add "X-Amz-Algorithm", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-SignedHeaders", valid_591201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591202: Call_GetAccount_591192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_591202.validator(path, query, header, formData, body)
  let scheme = call_591202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591202.url(scheme.get, call_591202.host, call_591202.base,
                         call_591202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591202, url, valid)

proc call*(call_591203: Call_GetAccount_591192): Recallable =
  ## getAccount
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  result = call_591203.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_591192(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "email.amazonaws.com",
                                      route: "/v1/email/account",
                                      validator: validate_GetAccount_591193,
                                      base: "/", url: url_GetAccount_591194,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlacklistReports_591204 = ref object of OpenApiRestCall_590364
proc url_GetBlacklistReports_591206(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBlacklistReports_591205(path: JsonNode; query: JsonNode;
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
  var valid_591207 = query.getOrDefault("BlacklistItemNames")
  valid_591207 = validateParameter(valid_591207, JArray, required = true, default = nil)
  if valid_591207 != nil:
    section.add "BlacklistItemNames", valid_591207
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
  var valid_591208 = header.getOrDefault("X-Amz-Signature")
  valid_591208 = validateParameter(valid_591208, JString, required = false,
                                 default = nil)
  if valid_591208 != nil:
    section.add "X-Amz-Signature", valid_591208
  var valid_591209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591209 = validateParameter(valid_591209, JString, required = false,
                                 default = nil)
  if valid_591209 != nil:
    section.add "X-Amz-Content-Sha256", valid_591209
  var valid_591210 = header.getOrDefault("X-Amz-Date")
  valid_591210 = validateParameter(valid_591210, JString, required = false,
                                 default = nil)
  if valid_591210 != nil:
    section.add "X-Amz-Date", valid_591210
  var valid_591211 = header.getOrDefault("X-Amz-Credential")
  valid_591211 = validateParameter(valid_591211, JString, required = false,
                                 default = nil)
  if valid_591211 != nil:
    section.add "X-Amz-Credential", valid_591211
  var valid_591212 = header.getOrDefault("X-Amz-Security-Token")
  valid_591212 = validateParameter(valid_591212, JString, required = false,
                                 default = nil)
  if valid_591212 != nil:
    section.add "X-Amz-Security-Token", valid_591212
  var valid_591213 = header.getOrDefault("X-Amz-Algorithm")
  valid_591213 = validateParameter(valid_591213, JString, required = false,
                                 default = nil)
  if valid_591213 != nil:
    section.add "X-Amz-Algorithm", valid_591213
  var valid_591214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591214 = validateParameter(valid_591214, JString, required = false,
                                 default = nil)
  if valid_591214 != nil:
    section.add "X-Amz-SignedHeaders", valid_591214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591215: Call_GetBlacklistReports_591204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ## 
  let valid = call_591215.validator(path, query, header, formData, body)
  let scheme = call_591215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591215.url(scheme.get, call_591215.host, call_591215.base,
                         call_591215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591215, url, valid)

proc call*(call_591216: Call_GetBlacklistReports_591204;
          BlacklistItemNames: JsonNode): Recallable =
  ## getBlacklistReports
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ##   BlacklistItemNames: JArray (required)
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon Pinpoint or Amazon SES.
  var query_591217 = newJObject()
  if BlacklistItemNames != nil:
    query_591217.add "BlacklistItemNames", BlacklistItemNames
  result = call_591216.call(nil, query_591217, nil, nil, nil)

var getBlacklistReports* = Call_GetBlacklistReports_591204(
    name: "getBlacklistReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/blacklist-report#BlacklistItemNames",
    validator: validate_GetBlacklistReports_591205, base: "/",
    url: url_GetBlacklistReports_591206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIp_591218 = ref object of OpenApiRestCall_590364
proc url_GetDedicatedIp_591220(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDedicatedIp_591219(path: JsonNode; query: JsonNode;
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
  var valid_591221 = path.getOrDefault("IP")
  valid_591221 = validateParameter(valid_591221, JString, required = true,
                                 default = nil)
  if valid_591221 != nil:
    section.add "IP", valid_591221
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
  var valid_591222 = header.getOrDefault("X-Amz-Signature")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-Signature", valid_591222
  var valid_591223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591223 = validateParameter(valid_591223, JString, required = false,
                                 default = nil)
  if valid_591223 != nil:
    section.add "X-Amz-Content-Sha256", valid_591223
  var valid_591224 = header.getOrDefault("X-Amz-Date")
  valid_591224 = validateParameter(valid_591224, JString, required = false,
                                 default = nil)
  if valid_591224 != nil:
    section.add "X-Amz-Date", valid_591224
  var valid_591225 = header.getOrDefault("X-Amz-Credential")
  valid_591225 = validateParameter(valid_591225, JString, required = false,
                                 default = nil)
  if valid_591225 != nil:
    section.add "X-Amz-Credential", valid_591225
  var valid_591226 = header.getOrDefault("X-Amz-Security-Token")
  valid_591226 = validateParameter(valid_591226, JString, required = false,
                                 default = nil)
  if valid_591226 != nil:
    section.add "X-Amz-Security-Token", valid_591226
  var valid_591227 = header.getOrDefault("X-Amz-Algorithm")
  valid_591227 = validateParameter(valid_591227, JString, required = false,
                                 default = nil)
  if valid_591227 != nil:
    section.add "X-Amz-Algorithm", valid_591227
  var valid_591228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591228 = validateParameter(valid_591228, JString, required = false,
                                 default = nil)
  if valid_591228 != nil:
    section.add "X-Amz-SignedHeaders", valid_591228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591229: Call_GetDedicatedIp_591218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  let valid = call_591229.validator(path, query, header, formData, body)
  let scheme = call_591229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591229.url(scheme.get, call_591229.host, call_591229.base,
                         call_591229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591229, url, valid)

proc call*(call_591230: Call_GetDedicatedIp_591218; IP: string): Recallable =
  ## getDedicatedIp
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  var path_591231 = newJObject()
  add(path_591231, "IP", newJString(IP))
  result = call_591230.call(path_591231, nil, nil, nil, nil)

var getDedicatedIp* = Call_GetDedicatedIp_591218(name: "getDedicatedIp",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips/{IP}", validator: validate_GetDedicatedIp_591219,
    base: "/", url: url_GetDedicatedIp_591220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIps_591232 = ref object of OpenApiRestCall_590364
proc url_GetDedicatedIps_591234(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDedicatedIps_591233(path: JsonNode; query: JsonNode;
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
  var valid_591235 = query.getOrDefault("NextToken")
  valid_591235 = validateParameter(valid_591235, JString, required = false,
                                 default = nil)
  if valid_591235 != nil:
    section.add "NextToken", valid_591235
  var valid_591236 = query.getOrDefault("PageSize")
  valid_591236 = validateParameter(valid_591236, JInt, required = false, default = nil)
  if valid_591236 != nil:
    section.add "PageSize", valid_591236
  var valid_591237 = query.getOrDefault("PoolName")
  valid_591237 = validateParameter(valid_591237, JString, required = false,
                                 default = nil)
  if valid_591237 != nil:
    section.add "PoolName", valid_591237
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
  var valid_591238 = header.getOrDefault("X-Amz-Signature")
  valid_591238 = validateParameter(valid_591238, JString, required = false,
                                 default = nil)
  if valid_591238 != nil:
    section.add "X-Amz-Signature", valid_591238
  var valid_591239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591239 = validateParameter(valid_591239, JString, required = false,
                                 default = nil)
  if valid_591239 != nil:
    section.add "X-Amz-Content-Sha256", valid_591239
  var valid_591240 = header.getOrDefault("X-Amz-Date")
  valid_591240 = validateParameter(valid_591240, JString, required = false,
                                 default = nil)
  if valid_591240 != nil:
    section.add "X-Amz-Date", valid_591240
  var valid_591241 = header.getOrDefault("X-Amz-Credential")
  valid_591241 = validateParameter(valid_591241, JString, required = false,
                                 default = nil)
  if valid_591241 != nil:
    section.add "X-Amz-Credential", valid_591241
  var valid_591242 = header.getOrDefault("X-Amz-Security-Token")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-Security-Token", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-Algorithm")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-Algorithm", valid_591243
  var valid_591244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "X-Amz-SignedHeaders", valid_591244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591245: Call_GetDedicatedIps_591232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_591245.validator(path, query, header, formData, body)
  let scheme = call_591245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591245.url(scheme.get, call_591245.host, call_591245.base,
                         call_591245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591245, url, valid)

proc call*(call_591246: Call_GetDedicatedIps_591232; NextToken: string = "";
          PageSize: int = 0; PoolName: string = ""): Recallable =
  ## getDedicatedIps
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   PoolName: string
  ##           : The name of a dedicated IP pool.
  var query_591247 = newJObject()
  add(query_591247, "NextToken", newJString(NextToken))
  add(query_591247, "PageSize", newJInt(PageSize))
  add(query_591247, "PoolName", newJString(PoolName))
  result = call_591246.call(nil, query_591247, nil, nil, nil)

var getDedicatedIps* = Call_GetDedicatedIps_591232(name: "getDedicatedIps",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips", validator: validate_GetDedicatedIps_591233,
    base: "/", url: url_GetDedicatedIps_591234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliverabilityDashboardOption_591260 = ref object of OpenApiRestCall_590364
proc url_PutDeliverabilityDashboardOption_591262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDeliverabilityDashboardOption_591261(path: JsonNode;
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
  var valid_591263 = header.getOrDefault("X-Amz-Signature")
  valid_591263 = validateParameter(valid_591263, JString, required = false,
                                 default = nil)
  if valid_591263 != nil:
    section.add "X-Amz-Signature", valid_591263
  var valid_591264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591264 = validateParameter(valid_591264, JString, required = false,
                                 default = nil)
  if valid_591264 != nil:
    section.add "X-Amz-Content-Sha256", valid_591264
  var valid_591265 = header.getOrDefault("X-Amz-Date")
  valid_591265 = validateParameter(valid_591265, JString, required = false,
                                 default = nil)
  if valid_591265 != nil:
    section.add "X-Amz-Date", valid_591265
  var valid_591266 = header.getOrDefault("X-Amz-Credential")
  valid_591266 = validateParameter(valid_591266, JString, required = false,
                                 default = nil)
  if valid_591266 != nil:
    section.add "X-Amz-Credential", valid_591266
  var valid_591267 = header.getOrDefault("X-Amz-Security-Token")
  valid_591267 = validateParameter(valid_591267, JString, required = false,
                                 default = nil)
  if valid_591267 != nil:
    section.add "X-Amz-Security-Token", valid_591267
  var valid_591268 = header.getOrDefault("X-Amz-Algorithm")
  valid_591268 = validateParameter(valid_591268, JString, required = false,
                                 default = nil)
  if valid_591268 != nil:
    section.add "X-Amz-Algorithm", valid_591268
  var valid_591269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591269 = validateParameter(valid_591269, JString, required = false,
                                 default = nil)
  if valid_591269 != nil:
    section.add "X-Amz-SignedHeaders", valid_591269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591271: Call_PutDeliverabilityDashboardOption_591260;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_591271.validator(path, query, header, formData, body)
  let scheme = call_591271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591271.url(scheme.get, call_591271.host, call_591271.base,
                         call_591271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591271, url, valid)

proc call*(call_591272: Call_PutDeliverabilityDashboardOption_591260;
          body: JsonNode): Recallable =
  ## putDeliverabilityDashboardOption
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ##   body: JObject (required)
  var body_591273 = newJObject()
  if body != nil:
    body_591273 = body
  result = call_591272.call(nil, nil, nil, nil, body_591273)

var putDeliverabilityDashboardOption* = Call_PutDeliverabilityDashboardOption_591260(
    name: "putDeliverabilityDashboardOption", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_PutDeliverabilityDashboardOption_591261, base: "/",
    url: url_PutDeliverabilityDashboardOption_591262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityDashboardOptions_591248 = ref object of OpenApiRestCall_590364
proc url_GetDeliverabilityDashboardOptions_591250(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeliverabilityDashboardOptions_591249(path: JsonNode;
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
  var valid_591251 = header.getOrDefault("X-Amz-Signature")
  valid_591251 = validateParameter(valid_591251, JString, required = false,
                                 default = nil)
  if valid_591251 != nil:
    section.add "X-Amz-Signature", valid_591251
  var valid_591252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591252 = validateParameter(valid_591252, JString, required = false,
                                 default = nil)
  if valid_591252 != nil:
    section.add "X-Amz-Content-Sha256", valid_591252
  var valid_591253 = header.getOrDefault("X-Amz-Date")
  valid_591253 = validateParameter(valid_591253, JString, required = false,
                                 default = nil)
  if valid_591253 != nil:
    section.add "X-Amz-Date", valid_591253
  var valid_591254 = header.getOrDefault("X-Amz-Credential")
  valid_591254 = validateParameter(valid_591254, JString, required = false,
                                 default = nil)
  if valid_591254 != nil:
    section.add "X-Amz-Credential", valid_591254
  var valid_591255 = header.getOrDefault("X-Amz-Security-Token")
  valid_591255 = validateParameter(valid_591255, JString, required = false,
                                 default = nil)
  if valid_591255 != nil:
    section.add "X-Amz-Security-Token", valid_591255
  var valid_591256 = header.getOrDefault("X-Amz-Algorithm")
  valid_591256 = validateParameter(valid_591256, JString, required = false,
                                 default = nil)
  if valid_591256 != nil:
    section.add "X-Amz-Algorithm", valid_591256
  var valid_591257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591257 = validateParameter(valid_591257, JString, required = false,
                                 default = nil)
  if valid_591257 != nil:
    section.add "X-Amz-SignedHeaders", valid_591257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591258: Call_GetDeliverabilityDashboardOptions_591248;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_591258.validator(path, query, header, formData, body)
  let scheme = call_591258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591258.url(scheme.get, call_591258.host, call_591258.base,
                         call_591258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591258, url, valid)

proc call*(call_591259: Call_GetDeliverabilityDashboardOptions_591248): Recallable =
  ## getDeliverabilityDashboardOptions
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  result = call_591259.call(nil, nil, nil, nil, nil)

var getDeliverabilityDashboardOptions* = Call_GetDeliverabilityDashboardOptions_591248(
    name: "getDeliverabilityDashboardOptions", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_GetDeliverabilityDashboardOptions_591249, base: "/",
    url: url_GetDeliverabilityDashboardOptions_591250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityTestReport_591274 = ref object of OpenApiRestCall_590364
proc url_GetDeliverabilityTestReport_591276(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetDeliverabilityTestReport_591275(path: JsonNode; query: JsonNode;
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
  var valid_591277 = path.getOrDefault("ReportId")
  valid_591277 = validateParameter(valid_591277, JString, required = true,
                                 default = nil)
  if valid_591277 != nil:
    section.add "ReportId", valid_591277
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
  var valid_591278 = header.getOrDefault("X-Amz-Signature")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Signature", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-Content-Sha256", valid_591279
  var valid_591280 = header.getOrDefault("X-Amz-Date")
  valid_591280 = validateParameter(valid_591280, JString, required = false,
                                 default = nil)
  if valid_591280 != nil:
    section.add "X-Amz-Date", valid_591280
  var valid_591281 = header.getOrDefault("X-Amz-Credential")
  valid_591281 = validateParameter(valid_591281, JString, required = false,
                                 default = nil)
  if valid_591281 != nil:
    section.add "X-Amz-Credential", valid_591281
  var valid_591282 = header.getOrDefault("X-Amz-Security-Token")
  valid_591282 = validateParameter(valid_591282, JString, required = false,
                                 default = nil)
  if valid_591282 != nil:
    section.add "X-Amz-Security-Token", valid_591282
  var valid_591283 = header.getOrDefault("X-Amz-Algorithm")
  valid_591283 = validateParameter(valid_591283, JString, required = false,
                                 default = nil)
  if valid_591283 != nil:
    section.add "X-Amz-Algorithm", valid_591283
  var valid_591284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591284 = validateParameter(valid_591284, JString, required = false,
                                 default = nil)
  if valid_591284 != nil:
    section.add "X-Amz-SignedHeaders", valid_591284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591285: Call_GetDeliverabilityTestReport_591274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  let valid = call_591285.validator(path, query, header, formData, body)
  let scheme = call_591285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591285.url(scheme.get, call_591285.host, call_591285.base,
                         call_591285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591285, url, valid)

proc call*(call_591286: Call_GetDeliverabilityTestReport_591274; ReportId: string): Recallable =
  ## getDeliverabilityTestReport
  ## Retrieve the results of a predictive inbox placement test.
  ##   ReportId: string (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  var path_591287 = newJObject()
  add(path_591287, "ReportId", newJString(ReportId))
  result = call_591286.call(path_591287, nil, nil, nil, nil)

var getDeliverabilityTestReport* = Call_GetDeliverabilityTestReport_591274(
    name: "getDeliverabilityTestReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports/{ReportId}",
    validator: validate_GetDeliverabilityTestReport_591275, base: "/",
    url: url_GetDeliverabilityTestReport_591276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDeliverabilityCampaign_591288 = ref object of OpenApiRestCall_590364
proc url_GetDomainDeliverabilityCampaign_591290(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetDomainDeliverabilityCampaign_591289(path: JsonNode;
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
  var valid_591291 = path.getOrDefault("CampaignId")
  valid_591291 = validateParameter(valid_591291, JString, required = true,
                                 default = nil)
  if valid_591291 != nil:
    section.add "CampaignId", valid_591291
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
  var valid_591292 = header.getOrDefault("X-Amz-Signature")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Signature", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Content-Sha256", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-Date")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-Date", valid_591294
  var valid_591295 = header.getOrDefault("X-Amz-Credential")
  valid_591295 = validateParameter(valid_591295, JString, required = false,
                                 default = nil)
  if valid_591295 != nil:
    section.add "X-Amz-Credential", valid_591295
  var valid_591296 = header.getOrDefault("X-Amz-Security-Token")
  valid_591296 = validateParameter(valid_591296, JString, required = false,
                                 default = nil)
  if valid_591296 != nil:
    section.add "X-Amz-Security-Token", valid_591296
  var valid_591297 = header.getOrDefault("X-Amz-Algorithm")
  valid_591297 = validateParameter(valid_591297, JString, required = false,
                                 default = nil)
  if valid_591297 != nil:
    section.add "X-Amz-Algorithm", valid_591297
  var valid_591298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591298 = validateParameter(valid_591298, JString, required = false,
                                 default = nil)
  if valid_591298 != nil:
    section.add "X-Amz-SignedHeaders", valid_591298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591299: Call_GetDomainDeliverabilityCampaign_591288;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ## 
  let valid = call_591299.validator(path, query, header, formData, body)
  let scheme = call_591299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591299.url(scheme.get, call_591299.host, call_591299.base,
                         call_591299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591299, url, valid)

proc call*(call_591300: Call_GetDomainDeliverabilityCampaign_591288;
          CampaignId: string): Recallable =
  ## getDomainDeliverabilityCampaign
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ##   CampaignId: string (required)
  ##             : The unique identifier for the campaign. Amazon Pinpoint automatically generates and assigns this identifier to a campaign. This value is not the same as the campaign identifier that Amazon Pinpoint assigns to campaigns that you create and manage by using the Amazon Pinpoint API or the Amazon Pinpoint console.
  var path_591301 = newJObject()
  add(path_591301, "CampaignId", newJString(CampaignId))
  result = call_591300.call(path_591301, nil, nil, nil, nil)

var getDomainDeliverabilityCampaign* = Call_GetDomainDeliverabilityCampaign_591288(
    name: "getDomainDeliverabilityCampaign", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/campaigns/{CampaignId}",
    validator: validate_GetDomainDeliverabilityCampaign_591289, base: "/",
    url: url_GetDomainDeliverabilityCampaign_591290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainStatisticsReport_591302 = ref object of OpenApiRestCall_590364
proc url_GetDomainStatisticsReport_591304(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetDomainStatisticsReport_591303(path: JsonNode; query: JsonNode;
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
  var valid_591305 = path.getOrDefault("Domain")
  valid_591305 = validateParameter(valid_591305, JString, required = true,
                                 default = nil)
  if valid_591305 != nil:
    section.add "Domain", valid_591305
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: JString (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_591306 = query.getOrDefault("EndDate")
  valid_591306 = validateParameter(valid_591306, JString, required = true,
                                 default = nil)
  if valid_591306 != nil:
    section.add "EndDate", valid_591306
  var valid_591307 = query.getOrDefault("StartDate")
  valid_591307 = validateParameter(valid_591307, JString, required = true,
                                 default = nil)
  if valid_591307 != nil:
    section.add "StartDate", valid_591307
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
  var valid_591308 = header.getOrDefault("X-Amz-Signature")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Signature", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-Content-Sha256", valid_591309
  var valid_591310 = header.getOrDefault("X-Amz-Date")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-Date", valid_591310
  var valid_591311 = header.getOrDefault("X-Amz-Credential")
  valid_591311 = validateParameter(valid_591311, JString, required = false,
                                 default = nil)
  if valid_591311 != nil:
    section.add "X-Amz-Credential", valid_591311
  var valid_591312 = header.getOrDefault("X-Amz-Security-Token")
  valid_591312 = validateParameter(valid_591312, JString, required = false,
                                 default = nil)
  if valid_591312 != nil:
    section.add "X-Amz-Security-Token", valid_591312
  var valid_591313 = header.getOrDefault("X-Amz-Algorithm")
  valid_591313 = validateParameter(valid_591313, JString, required = false,
                                 default = nil)
  if valid_591313 != nil:
    section.add "X-Amz-Algorithm", valid_591313
  var valid_591314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591314 = validateParameter(valid_591314, JString, required = false,
                                 default = nil)
  if valid_591314 != nil:
    section.add "X-Amz-SignedHeaders", valid_591314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591315: Call_GetDomainStatisticsReport_591302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  let valid = call_591315.validator(path, query, header, formData, body)
  let scheme = call_591315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591315.url(scheme.get, call_591315.host, call_591315.base,
                         call_591315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591315, url, valid)

proc call*(call_591316: Call_GetDomainStatisticsReport_591302; EndDate: string;
          Domain: string; StartDate: string): Recallable =
  ## getDomainStatisticsReport
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ##   EndDate: string (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   Domain: string (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  ##   StartDate: string (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  var path_591317 = newJObject()
  var query_591318 = newJObject()
  add(query_591318, "EndDate", newJString(EndDate))
  add(path_591317, "Domain", newJString(Domain))
  add(query_591318, "StartDate", newJString(StartDate))
  result = call_591316.call(path_591317, query_591318, nil, nil, nil)

var getDomainStatisticsReport* = Call_GetDomainStatisticsReport_591302(
    name: "getDomainStatisticsReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/statistics-report/{Domain}#StartDate&EndDate",
    validator: validate_GetDomainStatisticsReport_591303, base: "/",
    url: url_GetDomainStatisticsReport_591304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeliverabilityTestReports_591319 = ref object of OpenApiRestCall_590364
proc url_ListDeliverabilityTestReports_591321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeliverabilityTestReports_591320(path: JsonNode; query: JsonNode;
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
  var valid_591322 = query.getOrDefault("NextToken")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "NextToken", valid_591322
  var valid_591323 = query.getOrDefault("PageSize")
  valid_591323 = validateParameter(valid_591323, JInt, required = false, default = nil)
  if valid_591323 != nil:
    section.add "PageSize", valid_591323
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
  var valid_591324 = header.getOrDefault("X-Amz-Signature")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-Signature", valid_591324
  var valid_591325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "X-Amz-Content-Sha256", valid_591325
  var valid_591326 = header.getOrDefault("X-Amz-Date")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-Date", valid_591326
  var valid_591327 = header.getOrDefault("X-Amz-Credential")
  valid_591327 = validateParameter(valid_591327, JString, required = false,
                                 default = nil)
  if valid_591327 != nil:
    section.add "X-Amz-Credential", valid_591327
  var valid_591328 = header.getOrDefault("X-Amz-Security-Token")
  valid_591328 = validateParameter(valid_591328, JString, required = false,
                                 default = nil)
  if valid_591328 != nil:
    section.add "X-Amz-Security-Token", valid_591328
  var valid_591329 = header.getOrDefault("X-Amz-Algorithm")
  valid_591329 = validateParameter(valid_591329, JString, required = false,
                                 default = nil)
  if valid_591329 != nil:
    section.add "X-Amz-Algorithm", valid_591329
  var valid_591330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591330 = validateParameter(valid_591330, JString, required = false,
                                 default = nil)
  if valid_591330 != nil:
    section.add "X-Amz-SignedHeaders", valid_591330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591331: Call_ListDeliverabilityTestReports_591319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  let valid = call_591331.validator(path, query, header, formData, body)
  let scheme = call_591331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591331.url(scheme.get, call_591331.host, call_591331.base,
                         call_591331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591331, url, valid)

proc call*(call_591332: Call_ListDeliverabilityTestReports_591319;
          NextToken: string = ""; PageSize: int = 0): Recallable =
  ## listDeliverabilityTestReports
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  var query_591333 = newJObject()
  add(query_591333, "NextToken", newJString(NextToken))
  add(query_591333, "PageSize", newJInt(PageSize))
  result = call_591332.call(nil, query_591333, nil, nil, nil)

var listDeliverabilityTestReports* = Call_ListDeliverabilityTestReports_591319(
    name: "listDeliverabilityTestReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports",
    validator: validate_ListDeliverabilityTestReports_591320, base: "/",
    url: url_ListDeliverabilityTestReports_591321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainDeliverabilityCampaigns_591334 = ref object of OpenApiRestCall_590364
proc url_ListDomainDeliverabilityCampaigns_591336(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListDomainDeliverabilityCampaigns_591335(path: JsonNode;
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
  var valid_591337 = path.getOrDefault("SubscribedDomain")
  valid_591337 = validateParameter(valid_591337, JString, required = true,
                                 default = nil)
  if valid_591337 != nil:
    section.add "SubscribedDomain", valid_591337
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
  var valid_591338 = query.getOrDefault("EndDate")
  valid_591338 = validateParameter(valid_591338, JString, required = true,
                                 default = nil)
  if valid_591338 != nil:
    section.add "EndDate", valid_591338
  var valid_591339 = query.getOrDefault("NextToken")
  valid_591339 = validateParameter(valid_591339, JString, required = false,
                                 default = nil)
  if valid_591339 != nil:
    section.add "NextToken", valid_591339
  var valid_591340 = query.getOrDefault("PageSize")
  valid_591340 = validateParameter(valid_591340, JInt, required = false, default = nil)
  if valid_591340 != nil:
    section.add "PageSize", valid_591340
  var valid_591341 = query.getOrDefault("StartDate")
  valid_591341 = validateParameter(valid_591341, JString, required = true,
                                 default = nil)
  if valid_591341 != nil:
    section.add "StartDate", valid_591341
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
  var valid_591342 = header.getOrDefault("X-Amz-Signature")
  valid_591342 = validateParameter(valid_591342, JString, required = false,
                                 default = nil)
  if valid_591342 != nil:
    section.add "X-Amz-Signature", valid_591342
  var valid_591343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591343 = validateParameter(valid_591343, JString, required = false,
                                 default = nil)
  if valid_591343 != nil:
    section.add "X-Amz-Content-Sha256", valid_591343
  var valid_591344 = header.getOrDefault("X-Amz-Date")
  valid_591344 = validateParameter(valid_591344, JString, required = false,
                                 default = nil)
  if valid_591344 != nil:
    section.add "X-Amz-Date", valid_591344
  var valid_591345 = header.getOrDefault("X-Amz-Credential")
  valid_591345 = validateParameter(valid_591345, JString, required = false,
                                 default = nil)
  if valid_591345 != nil:
    section.add "X-Amz-Credential", valid_591345
  var valid_591346 = header.getOrDefault("X-Amz-Security-Token")
  valid_591346 = validateParameter(valid_591346, JString, required = false,
                                 default = nil)
  if valid_591346 != nil:
    section.add "X-Amz-Security-Token", valid_591346
  var valid_591347 = header.getOrDefault("X-Amz-Algorithm")
  valid_591347 = validateParameter(valid_591347, JString, required = false,
                                 default = nil)
  if valid_591347 != nil:
    section.add "X-Amz-Algorithm", valid_591347
  var valid_591348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591348 = validateParameter(valid_591348, JString, required = false,
                                 default = nil)
  if valid_591348 != nil:
    section.add "X-Amz-SignedHeaders", valid_591348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591349: Call_ListDomainDeliverabilityCampaigns_591334;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ## 
  let valid = call_591349.validator(path, query, header, formData, body)
  let scheme = call_591349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591349.url(scheme.get, call_591349.host, call_591349.base,
                         call_591349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591349, url, valid)

proc call*(call_591350: Call_ListDomainDeliverabilityCampaigns_591334;
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
  var path_591351 = newJObject()
  var query_591352 = newJObject()
  add(query_591352, "EndDate", newJString(EndDate))
  add(query_591352, "NextToken", newJString(NextToken))
  add(path_591351, "SubscribedDomain", newJString(SubscribedDomain))
  add(query_591352, "PageSize", newJInt(PageSize))
  add(query_591352, "StartDate", newJString(StartDate))
  result = call_591350.call(path_591351, query_591352, nil, nil, nil)

var listDomainDeliverabilityCampaigns* = Call_ListDomainDeliverabilityCampaigns_591334(
    name: "listDomainDeliverabilityCampaigns", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/domains/{SubscribedDomain}/campaigns#StartDate&EndDate",
    validator: validate_ListDomainDeliverabilityCampaigns_591335, base: "/",
    url: url_ListDomainDeliverabilityCampaigns_591336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591353 = ref object of OpenApiRestCall_590364
proc url_ListTagsForResource_591355(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_591354(path: JsonNode; query: JsonNode;
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
  var valid_591356 = query.getOrDefault("ResourceArn")
  valid_591356 = validateParameter(valid_591356, JString, required = true,
                                 default = nil)
  if valid_591356 != nil:
    section.add "ResourceArn", valid_591356
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
  var valid_591357 = header.getOrDefault("X-Amz-Signature")
  valid_591357 = validateParameter(valid_591357, JString, required = false,
                                 default = nil)
  if valid_591357 != nil:
    section.add "X-Amz-Signature", valid_591357
  var valid_591358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591358 = validateParameter(valid_591358, JString, required = false,
                                 default = nil)
  if valid_591358 != nil:
    section.add "X-Amz-Content-Sha256", valid_591358
  var valid_591359 = header.getOrDefault("X-Amz-Date")
  valid_591359 = validateParameter(valid_591359, JString, required = false,
                                 default = nil)
  if valid_591359 != nil:
    section.add "X-Amz-Date", valid_591359
  var valid_591360 = header.getOrDefault("X-Amz-Credential")
  valid_591360 = validateParameter(valid_591360, JString, required = false,
                                 default = nil)
  if valid_591360 != nil:
    section.add "X-Amz-Credential", valid_591360
  var valid_591361 = header.getOrDefault("X-Amz-Security-Token")
  valid_591361 = validateParameter(valid_591361, JString, required = false,
                                 default = nil)
  if valid_591361 != nil:
    section.add "X-Amz-Security-Token", valid_591361
  var valid_591362 = header.getOrDefault("X-Amz-Algorithm")
  valid_591362 = validateParameter(valid_591362, JString, required = false,
                                 default = nil)
  if valid_591362 != nil:
    section.add "X-Amz-Algorithm", valid_591362
  var valid_591363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591363 = validateParameter(valid_591363, JString, required = false,
                                 default = nil)
  if valid_591363 != nil:
    section.add "X-Amz-SignedHeaders", valid_591363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591364: Call_ListTagsForResource_591353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  let valid = call_591364.validator(path, query, header, formData, body)
  let scheme = call_591364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591364.url(scheme.get, call_591364.host, call_591364.base,
                         call_591364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591364, url, valid)

proc call*(call_591365: Call_ListTagsForResource_591353; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  var query_591366 = newJObject()
  add(query_591366, "ResourceArn", newJString(ResourceArn))
  result = call_591365.call(nil, query_591366, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_591353(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/tags#ResourceArn",
    validator: validate_ListTagsForResource_591354, base: "/",
    url: url_ListTagsForResource_591355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountDedicatedIpWarmupAttributes_591367 = ref object of OpenApiRestCall_590364
proc url_PutAccountDedicatedIpWarmupAttributes_591369(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutAccountDedicatedIpWarmupAttributes_591368(path: JsonNode;
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
  var valid_591370 = header.getOrDefault("X-Amz-Signature")
  valid_591370 = validateParameter(valid_591370, JString, required = false,
                                 default = nil)
  if valid_591370 != nil:
    section.add "X-Amz-Signature", valid_591370
  var valid_591371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591371 = validateParameter(valid_591371, JString, required = false,
                                 default = nil)
  if valid_591371 != nil:
    section.add "X-Amz-Content-Sha256", valid_591371
  var valid_591372 = header.getOrDefault("X-Amz-Date")
  valid_591372 = validateParameter(valid_591372, JString, required = false,
                                 default = nil)
  if valid_591372 != nil:
    section.add "X-Amz-Date", valid_591372
  var valid_591373 = header.getOrDefault("X-Amz-Credential")
  valid_591373 = validateParameter(valid_591373, JString, required = false,
                                 default = nil)
  if valid_591373 != nil:
    section.add "X-Amz-Credential", valid_591373
  var valid_591374 = header.getOrDefault("X-Amz-Security-Token")
  valid_591374 = validateParameter(valid_591374, JString, required = false,
                                 default = nil)
  if valid_591374 != nil:
    section.add "X-Amz-Security-Token", valid_591374
  var valid_591375 = header.getOrDefault("X-Amz-Algorithm")
  valid_591375 = validateParameter(valid_591375, JString, required = false,
                                 default = nil)
  if valid_591375 != nil:
    section.add "X-Amz-Algorithm", valid_591375
  var valid_591376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591376 = validateParameter(valid_591376, JString, required = false,
                                 default = nil)
  if valid_591376 != nil:
    section.add "X-Amz-SignedHeaders", valid_591376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591378: Call_PutAccountDedicatedIpWarmupAttributes_591367;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ## 
  let valid = call_591378.validator(path, query, header, formData, body)
  let scheme = call_591378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591378.url(scheme.get, call_591378.host, call_591378.base,
                         call_591378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591378, url, valid)

proc call*(call_591379: Call_PutAccountDedicatedIpWarmupAttributes_591367;
          body: JsonNode): Recallable =
  ## putAccountDedicatedIpWarmupAttributes
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ##   body: JObject (required)
  var body_591380 = newJObject()
  if body != nil:
    body_591380 = body
  result = call_591379.call(nil, nil, nil, nil, body_591380)

var putAccountDedicatedIpWarmupAttributes* = Call_PutAccountDedicatedIpWarmupAttributes_591367(
    name: "putAccountDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/dedicated-ips/warmup",
    validator: validate_PutAccountDedicatedIpWarmupAttributes_591368, base: "/",
    url: url_PutAccountDedicatedIpWarmupAttributes_591369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSendingAttributes_591381 = ref object of OpenApiRestCall_590364
proc url_PutAccountSendingAttributes_591383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutAccountSendingAttributes_591382(path: JsonNode; query: JsonNode;
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
  var valid_591384 = header.getOrDefault("X-Amz-Signature")
  valid_591384 = validateParameter(valid_591384, JString, required = false,
                                 default = nil)
  if valid_591384 != nil:
    section.add "X-Amz-Signature", valid_591384
  var valid_591385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591385 = validateParameter(valid_591385, JString, required = false,
                                 default = nil)
  if valid_591385 != nil:
    section.add "X-Amz-Content-Sha256", valid_591385
  var valid_591386 = header.getOrDefault("X-Amz-Date")
  valid_591386 = validateParameter(valid_591386, JString, required = false,
                                 default = nil)
  if valid_591386 != nil:
    section.add "X-Amz-Date", valid_591386
  var valid_591387 = header.getOrDefault("X-Amz-Credential")
  valid_591387 = validateParameter(valid_591387, JString, required = false,
                                 default = nil)
  if valid_591387 != nil:
    section.add "X-Amz-Credential", valid_591387
  var valid_591388 = header.getOrDefault("X-Amz-Security-Token")
  valid_591388 = validateParameter(valid_591388, JString, required = false,
                                 default = nil)
  if valid_591388 != nil:
    section.add "X-Amz-Security-Token", valid_591388
  var valid_591389 = header.getOrDefault("X-Amz-Algorithm")
  valid_591389 = validateParameter(valid_591389, JString, required = false,
                                 default = nil)
  if valid_591389 != nil:
    section.add "X-Amz-Algorithm", valid_591389
  var valid_591390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591390 = validateParameter(valid_591390, JString, required = false,
                                 default = nil)
  if valid_591390 != nil:
    section.add "X-Amz-SignedHeaders", valid_591390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591392: Call_PutAccountSendingAttributes_591381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enable or disable the ability of your account to send email.
  ## 
  let valid = call_591392.validator(path, query, header, formData, body)
  let scheme = call_591392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591392.url(scheme.get, call_591392.host, call_591392.base,
                         call_591392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591392, url, valid)

proc call*(call_591393: Call_PutAccountSendingAttributes_591381; body: JsonNode): Recallable =
  ## putAccountSendingAttributes
  ## Enable or disable the ability of your account to send email.
  ##   body: JObject (required)
  var body_591394 = newJObject()
  if body != nil:
    body_591394 = body
  result = call_591393.call(nil, nil, nil, nil, body_591394)

var putAccountSendingAttributes* = Call_PutAccountSendingAttributes_591381(
    name: "putAccountSendingAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/sending",
    validator: validate_PutAccountSendingAttributes_591382, base: "/",
    url: url_PutAccountSendingAttributes_591383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetDeliveryOptions_591395 = ref object of OpenApiRestCall_590364
proc url_PutConfigurationSetDeliveryOptions_591397(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PutConfigurationSetDeliveryOptions_591396(path: JsonNode;
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
  var valid_591398 = path.getOrDefault("ConfigurationSetName")
  valid_591398 = validateParameter(valid_591398, JString, required = true,
                                 default = nil)
  if valid_591398 != nil:
    section.add "ConfigurationSetName", valid_591398
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
  var valid_591399 = header.getOrDefault("X-Amz-Signature")
  valid_591399 = validateParameter(valid_591399, JString, required = false,
                                 default = nil)
  if valid_591399 != nil:
    section.add "X-Amz-Signature", valid_591399
  var valid_591400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591400 = validateParameter(valid_591400, JString, required = false,
                                 default = nil)
  if valid_591400 != nil:
    section.add "X-Amz-Content-Sha256", valid_591400
  var valid_591401 = header.getOrDefault("X-Amz-Date")
  valid_591401 = validateParameter(valid_591401, JString, required = false,
                                 default = nil)
  if valid_591401 != nil:
    section.add "X-Amz-Date", valid_591401
  var valid_591402 = header.getOrDefault("X-Amz-Credential")
  valid_591402 = validateParameter(valid_591402, JString, required = false,
                                 default = nil)
  if valid_591402 != nil:
    section.add "X-Amz-Credential", valid_591402
  var valid_591403 = header.getOrDefault("X-Amz-Security-Token")
  valid_591403 = validateParameter(valid_591403, JString, required = false,
                                 default = nil)
  if valid_591403 != nil:
    section.add "X-Amz-Security-Token", valid_591403
  var valid_591404 = header.getOrDefault("X-Amz-Algorithm")
  valid_591404 = validateParameter(valid_591404, JString, required = false,
                                 default = nil)
  if valid_591404 != nil:
    section.add "X-Amz-Algorithm", valid_591404
  var valid_591405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591405 = validateParameter(valid_591405, JString, required = false,
                                 default = nil)
  if valid_591405 != nil:
    section.add "X-Amz-SignedHeaders", valid_591405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591407: Call_PutConfigurationSetDeliveryOptions_591395;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  let valid = call_591407.validator(path, query, header, formData, body)
  let scheme = call_591407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591407.url(scheme.get, call_591407.host, call_591407.base,
                         call_591407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591407, url, valid)

proc call*(call_591408: Call_PutConfigurationSetDeliveryOptions_591395;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetDeliveryOptions
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_591409 = newJObject()
  var body_591410 = newJObject()
  add(path_591409, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_591410 = body
  result = call_591408.call(path_591409, nil, nil, nil, body_591410)

var putConfigurationSetDeliveryOptions* = Call_PutConfigurationSetDeliveryOptions_591395(
    name: "putConfigurationSetDeliveryOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/delivery-options",
    validator: validate_PutConfigurationSetDeliveryOptions_591396, base: "/",
    url: url_PutConfigurationSetDeliveryOptions_591397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetReputationOptions_591411 = ref object of OpenApiRestCall_590364
proc url_PutConfigurationSetReputationOptions_591413(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_PutConfigurationSetReputationOptions_591412(path: JsonNode;
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
  var valid_591414 = path.getOrDefault("ConfigurationSetName")
  valid_591414 = validateParameter(valid_591414, JString, required = true,
                                 default = nil)
  if valid_591414 != nil:
    section.add "ConfigurationSetName", valid_591414
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
  var valid_591415 = header.getOrDefault("X-Amz-Signature")
  valid_591415 = validateParameter(valid_591415, JString, required = false,
                                 default = nil)
  if valid_591415 != nil:
    section.add "X-Amz-Signature", valid_591415
  var valid_591416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591416 = validateParameter(valid_591416, JString, required = false,
                                 default = nil)
  if valid_591416 != nil:
    section.add "X-Amz-Content-Sha256", valid_591416
  var valid_591417 = header.getOrDefault("X-Amz-Date")
  valid_591417 = validateParameter(valid_591417, JString, required = false,
                                 default = nil)
  if valid_591417 != nil:
    section.add "X-Amz-Date", valid_591417
  var valid_591418 = header.getOrDefault("X-Amz-Credential")
  valid_591418 = validateParameter(valid_591418, JString, required = false,
                                 default = nil)
  if valid_591418 != nil:
    section.add "X-Amz-Credential", valid_591418
  var valid_591419 = header.getOrDefault("X-Amz-Security-Token")
  valid_591419 = validateParameter(valid_591419, JString, required = false,
                                 default = nil)
  if valid_591419 != nil:
    section.add "X-Amz-Security-Token", valid_591419
  var valid_591420 = header.getOrDefault("X-Amz-Algorithm")
  valid_591420 = validateParameter(valid_591420, JString, required = false,
                                 default = nil)
  if valid_591420 != nil:
    section.add "X-Amz-Algorithm", valid_591420
  var valid_591421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591421 = validateParameter(valid_591421, JString, required = false,
                                 default = nil)
  if valid_591421 != nil:
    section.add "X-Amz-SignedHeaders", valid_591421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591423: Call_PutConfigurationSetReputationOptions_591411;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_591423.validator(path, query, header, formData, body)
  let scheme = call_591423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591423.url(scheme.get, call_591423.host, call_591423.base,
                         call_591423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591423, url, valid)

proc call*(call_591424: Call_PutConfigurationSetReputationOptions_591411;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetReputationOptions
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_591425 = newJObject()
  var body_591426 = newJObject()
  add(path_591425, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_591426 = body
  result = call_591424.call(path_591425, nil, nil, nil, body_591426)

var putConfigurationSetReputationOptions* = Call_PutConfigurationSetReputationOptions_591411(
    name: "putConfigurationSetReputationOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/reputation-options",
    validator: validate_PutConfigurationSetReputationOptions_591412, base: "/",
    url: url_PutConfigurationSetReputationOptions_591413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSendingOptions_591427 = ref object of OpenApiRestCall_590364
proc url_PutConfigurationSetSendingOptions_591429(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PutConfigurationSetSendingOptions_591428(path: JsonNode;
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
  var valid_591430 = path.getOrDefault("ConfigurationSetName")
  valid_591430 = validateParameter(valid_591430, JString, required = true,
                                 default = nil)
  if valid_591430 != nil:
    section.add "ConfigurationSetName", valid_591430
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
  var valid_591431 = header.getOrDefault("X-Amz-Signature")
  valid_591431 = validateParameter(valid_591431, JString, required = false,
                                 default = nil)
  if valid_591431 != nil:
    section.add "X-Amz-Signature", valid_591431
  var valid_591432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591432 = validateParameter(valid_591432, JString, required = false,
                                 default = nil)
  if valid_591432 != nil:
    section.add "X-Amz-Content-Sha256", valid_591432
  var valid_591433 = header.getOrDefault("X-Amz-Date")
  valid_591433 = validateParameter(valid_591433, JString, required = false,
                                 default = nil)
  if valid_591433 != nil:
    section.add "X-Amz-Date", valid_591433
  var valid_591434 = header.getOrDefault("X-Amz-Credential")
  valid_591434 = validateParameter(valid_591434, JString, required = false,
                                 default = nil)
  if valid_591434 != nil:
    section.add "X-Amz-Credential", valid_591434
  var valid_591435 = header.getOrDefault("X-Amz-Security-Token")
  valid_591435 = validateParameter(valid_591435, JString, required = false,
                                 default = nil)
  if valid_591435 != nil:
    section.add "X-Amz-Security-Token", valid_591435
  var valid_591436 = header.getOrDefault("X-Amz-Algorithm")
  valid_591436 = validateParameter(valid_591436, JString, required = false,
                                 default = nil)
  if valid_591436 != nil:
    section.add "X-Amz-Algorithm", valid_591436
  var valid_591437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591437 = validateParameter(valid_591437, JString, required = false,
                                 default = nil)
  if valid_591437 != nil:
    section.add "X-Amz-SignedHeaders", valid_591437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591439: Call_PutConfigurationSetSendingOptions_591427;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_591439.validator(path, query, header, formData, body)
  let scheme = call_591439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591439.url(scheme.get, call_591439.host, call_591439.base,
                         call_591439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591439, url, valid)

proc call*(call_591440: Call_PutConfigurationSetSendingOptions_591427;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSendingOptions
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_591441 = newJObject()
  var body_591442 = newJObject()
  add(path_591441, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_591442 = body
  result = call_591440.call(path_591441, nil, nil, nil, body_591442)

var putConfigurationSetSendingOptions* = Call_PutConfigurationSetSendingOptions_591427(
    name: "putConfigurationSetSendingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}/sending",
    validator: validate_PutConfigurationSetSendingOptions_591428, base: "/",
    url: url_PutConfigurationSetSendingOptions_591429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetTrackingOptions_591443 = ref object of OpenApiRestCall_590364
proc url_PutConfigurationSetTrackingOptions_591445(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PutConfigurationSetTrackingOptions_591444(path: JsonNode;
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
  var valid_591446 = path.getOrDefault("ConfigurationSetName")
  valid_591446 = validateParameter(valid_591446, JString, required = true,
                                 default = nil)
  if valid_591446 != nil:
    section.add "ConfigurationSetName", valid_591446
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
  var valid_591447 = header.getOrDefault("X-Amz-Signature")
  valid_591447 = validateParameter(valid_591447, JString, required = false,
                                 default = nil)
  if valid_591447 != nil:
    section.add "X-Amz-Signature", valid_591447
  var valid_591448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591448 = validateParameter(valid_591448, JString, required = false,
                                 default = nil)
  if valid_591448 != nil:
    section.add "X-Amz-Content-Sha256", valid_591448
  var valid_591449 = header.getOrDefault("X-Amz-Date")
  valid_591449 = validateParameter(valid_591449, JString, required = false,
                                 default = nil)
  if valid_591449 != nil:
    section.add "X-Amz-Date", valid_591449
  var valid_591450 = header.getOrDefault("X-Amz-Credential")
  valid_591450 = validateParameter(valid_591450, JString, required = false,
                                 default = nil)
  if valid_591450 != nil:
    section.add "X-Amz-Credential", valid_591450
  var valid_591451 = header.getOrDefault("X-Amz-Security-Token")
  valid_591451 = validateParameter(valid_591451, JString, required = false,
                                 default = nil)
  if valid_591451 != nil:
    section.add "X-Amz-Security-Token", valid_591451
  var valid_591452 = header.getOrDefault("X-Amz-Algorithm")
  valid_591452 = validateParameter(valid_591452, JString, required = false,
                                 default = nil)
  if valid_591452 != nil:
    section.add "X-Amz-Algorithm", valid_591452
  var valid_591453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591453 = validateParameter(valid_591453, JString, required = false,
                                 default = nil)
  if valid_591453 != nil:
    section.add "X-Amz-SignedHeaders", valid_591453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591455: Call_PutConfigurationSetTrackingOptions_591443;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ## 
  let valid = call_591455.validator(path, query, header, formData, body)
  let scheme = call_591455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591455.url(scheme.get, call_591455.host, call_591455.base,
                         call_591455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591455, url, valid)

proc call*(call_591456: Call_PutConfigurationSetTrackingOptions_591443;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetTrackingOptions
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_591457 = newJObject()
  var body_591458 = newJObject()
  add(path_591457, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_591458 = body
  result = call_591456.call(path_591457, nil, nil, nil, body_591458)

var putConfigurationSetTrackingOptions* = Call_PutConfigurationSetTrackingOptions_591443(
    name: "putConfigurationSetTrackingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/tracking-options",
    validator: validate_PutConfigurationSetTrackingOptions_591444, base: "/",
    url: url_PutConfigurationSetTrackingOptions_591445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpInPool_591459 = ref object of OpenApiRestCall_590364
proc url_PutDedicatedIpInPool_591461(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PutDedicatedIpInPool_591460(path: JsonNode; query: JsonNode;
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
  var valid_591462 = path.getOrDefault("IP")
  valid_591462 = validateParameter(valid_591462, JString, required = true,
                                 default = nil)
  if valid_591462 != nil:
    section.add "IP", valid_591462
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
  var valid_591463 = header.getOrDefault("X-Amz-Signature")
  valid_591463 = validateParameter(valid_591463, JString, required = false,
                                 default = nil)
  if valid_591463 != nil:
    section.add "X-Amz-Signature", valid_591463
  var valid_591464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591464 = validateParameter(valid_591464, JString, required = false,
                                 default = nil)
  if valid_591464 != nil:
    section.add "X-Amz-Content-Sha256", valid_591464
  var valid_591465 = header.getOrDefault("X-Amz-Date")
  valid_591465 = validateParameter(valid_591465, JString, required = false,
                                 default = nil)
  if valid_591465 != nil:
    section.add "X-Amz-Date", valid_591465
  var valid_591466 = header.getOrDefault("X-Amz-Credential")
  valid_591466 = validateParameter(valid_591466, JString, required = false,
                                 default = nil)
  if valid_591466 != nil:
    section.add "X-Amz-Credential", valid_591466
  var valid_591467 = header.getOrDefault("X-Amz-Security-Token")
  valid_591467 = validateParameter(valid_591467, JString, required = false,
                                 default = nil)
  if valid_591467 != nil:
    section.add "X-Amz-Security-Token", valid_591467
  var valid_591468 = header.getOrDefault("X-Amz-Algorithm")
  valid_591468 = validateParameter(valid_591468, JString, required = false,
                                 default = nil)
  if valid_591468 != nil:
    section.add "X-Amz-Algorithm", valid_591468
  var valid_591469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591469 = validateParameter(valid_591469, JString, required = false,
                                 default = nil)
  if valid_591469 != nil:
    section.add "X-Amz-SignedHeaders", valid_591469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591471: Call_PutDedicatedIpInPool_591459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  let valid = call_591471.validator(path, query, header, formData, body)
  let scheme = call_591471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591471.url(scheme.get, call_591471.host, call_591471.base,
                         call_591471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591471, url, valid)

proc call*(call_591472: Call_PutDedicatedIpInPool_591459; IP: string; body: JsonNode): Recallable =
  ## putDedicatedIpInPool
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_591473 = newJObject()
  var body_591474 = newJObject()
  add(path_591473, "IP", newJString(IP))
  if body != nil:
    body_591474 = body
  result = call_591472.call(path_591473, nil, nil, nil, body_591474)

var putDedicatedIpInPool* = Call_PutDedicatedIpInPool_591459(
    name: "putDedicatedIpInPool", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/pool",
    validator: validate_PutDedicatedIpInPool_591460, base: "/",
    url: url_PutDedicatedIpInPool_591461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpWarmupAttributes_591475 = ref object of OpenApiRestCall_590364
proc url_PutDedicatedIpWarmupAttributes_591477(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PutDedicatedIpWarmupAttributes_591476(path: JsonNode;
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
  var valid_591478 = path.getOrDefault("IP")
  valid_591478 = validateParameter(valid_591478, JString, required = true,
                                 default = nil)
  if valid_591478 != nil:
    section.add "IP", valid_591478
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
  var valid_591479 = header.getOrDefault("X-Amz-Signature")
  valid_591479 = validateParameter(valid_591479, JString, required = false,
                                 default = nil)
  if valid_591479 != nil:
    section.add "X-Amz-Signature", valid_591479
  var valid_591480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591480 = validateParameter(valid_591480, JString, required = false,
                                 default = nil)
  if valid_591480 != nil:
    section.add "X-Amz-Content-Sha256", valid_591480
  var valid_591481 = header.getOrDefault("X-Amz-Date")
  valid_591481 = validateParameter(valid_591481, JString, required = false,
                                 default = nil)
  if valid_591481 != nil:
    section.add "X-Amz-Date", valid_591481
  var valid_591482 = header.getOrDefault("X-Amz-Credential")
  valid_591482 = validateParameter(valid_591482, JString, required = false,
                                 default = nil)
  if valid_591482 != nil:
    section.add "X-Amz-Credential", valid_591482
  var valid_591483 = header.getOrDefault("X-Amz-Security-Token")
  valid_591483 = validateParameter(valid_591483, JString, required = false,
                                 default = nil)
  if valid_591483 != nil:
    section.add "X-Amz-Security-Token", valid_591483
  var valid_591484 = header.getOrDefault("X-Amz-Algorithm")
  valid_591484 = validateParameter(valid_591484, JString, required = false,
                                 default = nil)
  if valid_591484 != nil:
    section.add "X-Amz-Algorithm", valid_591484
  var valid_591485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591485 = validateParameter(valid_591485, JString, required = false,
                                 default = nil)
  if valid_591485 != nil:
    section.add "X-Amz-SignedHeaders", valid_591485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591487: Call_PutDedicatedIpWarmupAttributes_591475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_591487.validator(path, query, header, formData, body)
  let scheme = call_591487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591487.url(scheme.get, call_591487.host, call_591487.base,
                         call_591487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591487, url, valid)

proc call*(call_591488: Call_PutDedicatedIpWarmupAttributes_591475; IP: string;
          body: JsonNode): Recallable =
  ## putDedicatedIpWarmupAttributes
  ## <p/>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_591489 = newJObject()
  var body_591490 = newJObject()
  add(path_591489, "IP", newJString(IP))
  if body != nil:
    body_591490 = body
  result = call_591488.call(path_591489, nil, nil, nil, body_591490)

var putDedicatedIpWarmupAttributes* = Call_PutDedicatedIpWarmupAttributes_591475(
    name: "putDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/warmup",
    validator: validate_PutDedicatedIpWarmupAttributes_591476, base: "/",
    url: url_PutDedicatedIpWarmupAttributes_591477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimAttributes_591491 = ref object of OpenApiRestCall_590364
proc url_PutEmailIdentityDkimAttributes_591493(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PutEmailIdentityDkimAttributes_591492(path: JsonNode;
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
  var valid_591494 = path.getOrDefault("EmailIdentity")
  valid_591494 = validateParameter(valid_591494, JString, required = true,
                                 default = nil)
  if valid_591494 != nil:
    section.add "EmailIdentity", valid_591494
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
  var valid_591495 = header.getOrDefault("X-Amz-Signature")
  valid_591495 = validateParameter(valid_591495, JString, required = false,
                                 default = nil)
  if valid_591495 != nil:
    section.add "X-Amz-Signature", valid_591495
  var valid_591496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591496 = validateParameter(valid_591496, JString, required = false,
                                 default = nil)
  if valid_591496 != nil:
    section.add "X-Amz-Content-Sha256", valid_591496
  var valid_591497 = header.getOrDefault("X-Amz-Date")
  valid_591497 = validateParameter(valid_591497, JString, required = false,
                                 default = nil)
  if valid_591497 != nil:
    section.add "X-Amz-Date", valid_591497
  var valid_591498 = header.getOrDefault("X-Amz-Credential")
  valid_591498 = validateParameter(valid_591498, JString, required = false,
                                 default = nil)
  if valid_591498 != nil:
    section.add "X-Amz-Credential", valid_591498
  var valid_591499 = header.getOrDefault("X-Amz-Security-Token")
  valid_591499 = validateParameter(valid_591499, JString, required = false,
                                 default = nil)
  if valid_591499 != nil:
    section.add "X-Amz-Security-Token", valid_591499
  var valid_591500 = header.getOrDefault("X-Amz-Algorithm")
  valid_591500 = validateParameter(valid_591500, JString, required = false,
                                 default = nil)
  if valid_591500 != nil:
    section.add "X-Amz-Algorithm", valid_591500
  var valid_591501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591501 = validateParameter(valid_591501, JString, required = false,
                                 default = nil)
  if valid_591501 != nil:
    section.add "X-Amz-SignedHeaders", valid_591501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591503: Call_PutEmailIdentityDkimAttributes_591491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to enable or disable DKIM authentication for an email identity.
  ## 
  let valid = call_591503.validator(path, query, header, formData, body)
  let scheme = call_591503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591503.url(scheme.get, call_591503.host, call_591503.base,
                         call_591503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591503, url, valid)

proc call*(call_591504: Call_PutEmailIdentityDkimAttributes_591491;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityDkimAttributes
  ## Used to enable or disable DKIM authentication for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to change the DKIM settings for.
  ##   body: JObject (required)
  var path_591505 = newJObject()
  var body_591506 = newJObject()
  add(path_591505, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_591506 = body
  result = call_591504.call(path_591505, nil, nil, nil, body_591506)

var putEmailIdentityDkimAttributes* = Call_PutEmailIdentityDkimAttributes_591491(
    name: "putEmailIdentityDkimAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/dkim",
    validator: validate_PutEmailIdentityDkimAttributes_591492, base: "/",
    url: url_PutEmailIdentityDkimAttributes_591493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityFeedbackAttributes_591507 = ref object of OpenApiRestCall_590364
proc url_PutEmailIdentityFeedbackAttributes_591509(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PutEmailIdentityFeedbackAttributes_591508(path: JsonNode;
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
  var valid_591510 = path.getOrDefault("EmailIdentity")
  valid_591510 = validateParameter(valid_591510, JString, required = true,
                                 default = nil)
  if valid_591510 != nil:
    section.add "EmailIdentity", valid_591510
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
  var valid_591511 = header.getOrDefault("X-Amz-Signature")
  valid_591511 = validateParameter(valid_591511, JString, required = false,
                                 default = nil)
  if valid_591511 != nil:
    section.add "X-Amz-Signature", valid_591511
  var valid_591512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591512 = validateParameter(valid_591512, JString, required = false,
                                 default = nil)
  if valid_591512 != nil:
    section.add "X-Amz-Content-Sha256", valid_591512
  var valid_591513 = header.getOrDefault("X-Amz-Date")
  valid_591513 = validateParameter(valid_591513, JString, required = false,
                                 default = nil)
  if valid_591513 != nil:
    section.add "X-Amz-Date", valid_591513
  var valid_591514 = header.getOrDefault("X-Amz-Credential")
  valid_591514 = validateParameter(valid_591514, JString, required = false,
                                 default = nil)
  if valid_591514 != nil:
    section.add "X-Amz-Credential", valid_591514
  var valid_591515 = header.getOrDefault("X-Amz-Security-Token")
  valid_591515 = validateParameter(valid_591515, JString, required = false,
                                 default = nil)
  if valid_591515 != nil:
    section.add "X-Amz-Security-Token", valid_591515
  var valid_591516 = header.getOrDefault("X-Amz-Algorithm")
  valid_591516 = validateParameter(valid_591516, JString, required = false,
                                 default = nil)
  if valid_591516 != nil:
    section.add "X-Amz-Algorithm", valid_591516
  var valid_591517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591517 = validateParameter(valid_591517, JString, required = false,
                                 default = nil)
  if valid_591517 != nil:
    section.add "X-Amz-SignedHeaders", valid_591517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591519: Call_PutEmailIdentityFeedbackAttributes_591507;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  let valid = call_591519.validator(path, query, header, formData, body)
  let scheme = call_591519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591519.url(scheme.get, call_591519.host, call_591519.base,
                         call_591519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591519, url, valid)

proc call*(call_591520: Call_PutEmailIdentityFeedbackAttributes_591507;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityFeedbackAttributes
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  ##   body: JObject (required)
  var path_591521 = newJObject()
  var body_591522 = newJObject()
  add(path_591521, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_591522 = body
  result = call_591520.call(path_591521, nil, nil, nil, body_591522)

var putEmailIdentityFeedbackAttributes* = Call_PutEmailIdentityFeedbackAttributes_591507(
    name: "putEmailIdentityFeedbackAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/feedback",
    validator: validate_PutEmailIdentityFeedbackAttributes_591508, base: "/",
    url: url_PutEmailIdentityFeedbackAttributes_591509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityMailFromAttributes_591523 = ref object of OpenApiRestCall_590364
proc url_PutEmailIdentityMailFromAttributes_591525(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PutEmailIdentityMailFromAttributes_591524(path: JsonNode;
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
  var valid_591526 = path.getOrDefault("EmailIdentity")
  valid_591526 = validateParameter(valid_591526, JString, required = true,
                                 default = nil)
  if valid_591526 != nil:
    section.add "EmailIdentity", valid_591526
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
  var valid_591527 = header.getOrDefault("X-Amz-Signature")
  valid_591527 = validateParameter(valid_591527, JString, required = false,
                                 default = nil)
  if valid_591527 != nil:
    section.add "X-Amz-Signature", valid_591527
  var valid_591528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591528 = validateParameter(valid_591528, JString, required = false,
                                 default = nil)
  if valid_591528 != nil:
    section.add "X-Amz-Content-Sha256", valid_591528
  var valid_591529 = header.getOrDefault("X-Amz-Date")
  valid_591529 = validateParameter(valid_591529, JString, required = false,
                                 default = nil)
  if valid_591529 != nil:
    section.add "X-Amz-Date", valid_591529
  var valid_591530 = header.getOrDefault("X-Amz-Credential")
  valid_591530 = validateParameter(valid_591530, JString, required = false,
                                 default = nil)
  if valid_591530 != nil:
    section.add "X-Amz-Credential", valid_591530
  var valid_591531 = header.getOrDefault("X-Amz-Security-Token")
  valid_591531 = validateParameter(valid_591531, JString, required = false,
                                 default = nil)
  if valid_591531 != nil:
    section.add "X-Amz-Security-Token", valid_591531
  var valid_591532 = header.getOrDefault("X-Amz-Algorithm")
  valid_591532 = validateParameter(valid_591532, JString, required = false,
                                 default = nil)
  if valid_591532 != nil:
    section.add "X-Amz-Algorithm", valid_591532
  var valid_591533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591533 = validateParameter(valid_591533, JString, required = false,
                                 default = nil)
  if valid_591533 != nil:
    section.add "X-Amz-SignedHeaders", valid_591533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591535: Call_PutEmailIdentityMailFromAttributes_591523;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ## 
  let valid = call_591535.validator(path, query, header, formData, body)
  let scheme = call_591535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591535.url(scheme.get, call_591535.host, call_591535.base,
                         call_591535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591535, url, valid)

proc call*(call_591536: Call_PutEmailIdentityMailFromAttributes_591523;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityMailFromAttributes
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  ##   body: JObject (required)
  var path_591537 = newJObject()
  var body_591538 = newJObject()
  add(path_591537, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_591538 = body
  result = call_591536.call(path_591537, nil, nil, nil, body_591538)

var putEmailIdentityMailFromAttributes* = Call_PutEmailIdentityMailFromAttributes_591523(
    name: "putEmailIdentityMailFromAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/mail-from",
    validator: validate_PutEmailIdentityMailFromAttributes_591524, base: "/",
    url: url_PutEmailIdentityMailFromAttributes_591525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEmail_591539 = ref object of OpenApiRestCall_590364
proc url_SendEmail_591541(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendEmail_591540(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591542 = header.getOrDefault("X-Amz-Signature")
  valid_591542 = validateParameter(valid_591542, JString, required = false,
                                 default = nil)
  if valid_591542 != nil:
    section.add "X-Amz-Signature", valid_591542
  var valid_591543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591543 = validateParameter(valid_591543, JString, required = false,
                                 default = nil)
  if valid_591543 != nil:
    section.add "X-Amz-Content-Sha256", valid_591543
  var valid_591544 = header.getOrDefault("X-Amz-Date")
  valid_591544 = validateParameter(valid_591544, JString, required = false,
                                 default = nil)
  if valid_591544 != nil:
    section.add "X-Amz-Date", valid_591544
  var valid_591545 = header.getOrDefault("X-Amz-Credential")
  valid_591545 = validateParameter(valid_591545, JString, required = false,
                                 default = nil)
  if valid_591545 != nil:
    section.add "X-Amz-Credential", valid_591545
  var valid_591546 = header.getOrDefault("X-Amz-Security-Token")
  valid_591546 = validateParameter(valid_591546, JString, required = false,
                                 default = nil)
  if valid_591546 != nil:
    section.add "X-Amz-Security-Token", valid_591546
  var valid_591547 = header.getOrDefault("X-Amz-Algorithm")
  valid_591547 = validateParameter(valid_591547, JString, required = false,
                                 default = nil)
  if valid_591547 != nil:
    section.add "X-Amz-Algorithm", valid_591547
  var valid_591548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591548 = validateParameter(valid_591548, JString, required = false,
                                 default = nil)
  if valid_591548 != nil:
    section.add "X-Amz-SignedHeaders", valid_591548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591550: Call_SendEmail_591539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  let valid = call_591550.validator(path, query, header, formData, body)
  let scheme = call_591550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591550.url(scheme.get, call_591550.host, call_591550.base,
                         call_591550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591550, url, valid)

proc call*(call_591551: Call_SendEmail_591539; body: JsonNode): Recallable =
  ## sendEmail
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ##   body: JObject (required)
  var body_591552 = newJObject()
  if body != nil:
    body_591552 = body
  result = call_591551.call(nil, nil, nil, nil, body_591552)

var sendEmail* = Call_SendEmail_591539(name: "sendEmail", meth: HttpMethod.HttpPost,
                                    host: "email.amazonaws.com",
                                    route: "/v1/email/outbound-emails",
                                    validator: validate_SendEmail_591540,
                                    base: "/", url: url_SendEmail_591541,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591553 = ref object of OpenApiRestCall_590364
proc url_TagResource_591555(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_591554(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591556 = header.getOrDefault("X-Amz-Signature")
  valid_591556 = validateParameter(valid_591556, JString, required = false,
                                 default = nil)
  if valid_591556 != nil:
    section.add "X-Amz-Signature", valid_591556
  var valid_591557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591557 = validateParameter(valid_591557, JString, required = false,
                                 default = nil)
  if valid_591557 != nil:
    section.add "X-Amz-Content-Sha256", valid_591557
  var valid_591558 = header.getOrDefault("X-Amz-Date")
  valid_591558 = validateParameter(valid_591558, JString, required = false,
                                 default = nil)
  if valid_591558 != nil:
    section.add "X-Amz-Date", valid_591558
  var valid_591559 = header.getOrDefault("X-Amz-Credential")
  valid_591559 = validateParameter(valid_591559, JString, required = false,
                                 default = nil)
  if valid_591559 != nil:
    section.add "X-Amz-Credential", valid_591559
  var valid_591560 = header.getOrDefault("X-Amz-Security-Token")
  valid_591560 = validateParameter(valid_591560, JString, required = false,
                                 default = nil)
  if valid_591560 != nil:
    section.add "X-Amz-Security-Token", valid_591560
  var valid_591561 = header.getOrDefault("X-Amz-Algorithm")
  valid_591561 = validateParameter(valid_591561, JString, required = false,
                                 default = nil)
  if valid_591561 != nil:
    section.add "X-Amz-Algorithm", valid_591561
  var valid_591562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591562 = validateParameter(valid_591562, JString, required = false,
                                 default = nil)
  if valid_591562 != nil:
    section.add "X-Amz-SignedHeaders", valid_591562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591564: Call_TagResource_591553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  let valid = call_591564.validator(path, query, header, formData, body)
  let scheme = call_591564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591564.url(scheme.get, call_591564.host, call_591564.base,
                         call_591564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591564, url, valid)

proc call*(call_591565: Call_TagResource_591553; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   body: JObject (required)
  var body_591566 = newJObject()
  if body != nil:
    body_591566 = body
  result = call_591565.call(nil, nil, nil, nil, body_591566)

var tagResource* = Call_TagResource_591553(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "email.amazonaws.com",
                                        route: "/v1/email/tags",
                                        validator: validate_TagResource_591554,
                                        base: "/", url: url_TagResource_591555,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591567 = ref object of OpenApiRestCall_590364
proc url_UntagResource_591569(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_591568(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591570 = query.getOrDefault("TagKeys")
  valid_591570 = validateParameter(valid_591570, JArray, required = true, default = nil)
  if valid_591570 != nil:
    section.add "TagKeys", valid_591570
  var valid_591571 = query.getOrDefault("ResourceArn")
  valid_591571 = validateParameter(valid_591571, JString, required = true,
                                 default = nil)
  if valid_591571 != nil:
    section.add "ResourceArn", valid_591571
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
  var valid_591572 = header.getOrDefault("X-Amz-Signature")
  valid_591572 = validateParameter(valid_591572, JString, required = false,
                                 default = nil)
  if valid_591572 != nil:
    section.add "X-Amz-Signature", valid_591572
  var valid_591573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591573 = validateParameter(valid_591573, JString, required = false,
                                 default = nil)
  if valid_591573 != nil:
    section.add "X-Amz-Content-Sha256", valid_591573
  var valid_591574 = header.getOrDefault("X-Amz-Date")
  valid_591574 = validateParameter(valid_591574, JString, required = false,
                                 default = nil)
  if valid_591574 != nil:
    section.add "X-Amz-Date", valid_591574
  var valid_591575 = header.getOrDefault("X-Amz-Credential")
  valid_591575 = validateParameter(valid_591575, JString, required = false,
                                 default = nil)
  if valid_591575 != nil:
    section.add "X-Amz-Credential", valid_591575
  var valid_591576 = header.getOrDefault("X-Amz-Security-Token")
  valid_591576 = validateParameter(valid_591576, JString, required = false,
                                 default = nil)
  if valid_591576 != nil:
    section.add "X-Amz-Security-Token", valid_591576
  var valid_591577 = header.getOrDefault("X-Amz-Algorithm")
  valid_591577 = validateParameter(valid_591577, JString, required = false,
                                 default = nil)
  if valid_591577 != nil:
    section.add "X-Amz-Algorithm", valid_591577
  var valid_591578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591578 = validateParameter(valid_591578, JString, required = false,
                                 default = nil)
  if valid_591578 != nil:
    section.add "X-Amz-SignedHeaders", valid_591578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591579: Call_UntagResource_591567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  let valid = call_591579.validator(path, query, header, formData, body)
  let scheme = call_591579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591579.url(scheme.get, call_591579.host, call_591579.base,
                         call_591579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591579, url, valid)

proc call*(call_591580: Call_UntagResource_591567; TagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified resource.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  var query_591581 = newJObject()
  if TagKeys != nil:
    query_591581.add "TagKeys", TagKeys
  add(query_591581, "ResourceArn", newJString(ResourceArn))
  result = call_591580.call(nil, query_591581, nil, nil, nil)

var untagResource* = Call_UntagResource_591567(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "email.amazonaws.com",
    route: "/v1/email/tags#ResourceArn&TagKeys",
    validator: validate_UntagResource_591568, base: "/", url: url_UntagResource_591569,
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
