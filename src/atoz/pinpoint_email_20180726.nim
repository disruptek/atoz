
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_CreateConfigurationSet_606184 = ref object of OpenApiRestCall_605589
proc url_CreateConfigurationSet_606186(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConfigurationSet_606185(path: JsonNode; query: JsonNode;
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
  var valid_606187 = header.getOrDefault("X-Amz-Signature")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Signature", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Content-Sha256", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Date")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Date", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Credential")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Credential", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Security-Token")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Security-Token", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Algorithm")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Algorithm", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-SignedHeaders", valid_606193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606195: Call_CreateConfigurationSet_606184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  let valid = call_606195.validator(path, query, header, formData, body)
  let scheme = call_606195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606195.url(scheme.get, call_606195.host, call_606195.base,
                         call_606195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606195, url, valid)

proc call*(call_606196: Call_CreateConfigurationSet_606184; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ##   body: JObject (required)
  var body_606197 = newJObject()
  if body != nil:
    body_606197 = body
  result = call_606196.call(nil, nil, nil, nil, body_606197)

var createConfigurationSet* = Call_CreateConfigurationSet_606184(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_CreateConfigurationSet_606185, base: "/",
    url: url_CreateConfigurationSet_606186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_605927 = ref object of OpenApiRestCall_605589
proc url_ListConfigurationSets_605929(protocol: Scheme; host: string; base: string;
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

proc validate_ListConfigurationSets_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = query.getOrDefault("NextToken")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "NextToken", valid_606041
  var valid_606042 = query.getOrDefault("PageSize")
  valid_606042 = validateParameter(valid_606042, JInt, required = false, default = nil)
  if valid_606042 != nil:
    section.add "PageSize", valid_606042
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
  var valid_606043 = header.getOrDefault("X-Amz-Signature")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Signature", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Content-Sha256", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Date")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Date", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Credential")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Credential", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Security-Token")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Security-Token", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Algorithm")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Algorithm", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-SignedHeaders", valid_606049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606072: Call_ListConfigurationSets_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_606072.validator(path, query, header, formData, body)
  let scheme = call_606072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606072.url(scheme.get, call_606072.host, call_606072.base,
                         call_606072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606072, url, valid)

proc call*(call_606143: Call_ListConfigurationSets_605927; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listConfigurationSets
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  var query_606144 = newJObject()
  add(query_606144, "NextToken", newJString(NextToken))
  add(query_606144, "PageSize", newJInt(PageSize))
  result = call_606143.call(nil, query_606144, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_605927(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_ListConfigurationSets_605928, base: "/",
    url: url_ListConfigurationSets_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_606226 = ref object of OpenApiRestCall_605589
proc url_CreateConfigurationSetEventDestination_606228(protocol: Scheme;
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

proc validate_CreateConfigurationSetEventDestination_606227(path: JsonNode;
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
  var valid_606229 = path.getOrDefault("ConfigurationSetName")
  valid_606229 = validateParameter(valid_606229, JString, required = true,
                                 default = nil)
  if valid_606229 != nil:
    section.add "ConfigurationSetName", valid_606229
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
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_CreateConfigurationSetEventDestination_606226;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CreateConfigurationSetEventDestination_606226;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_606240 = newJObject()
  var body_606241 = newJObject()
  add(path_606240, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_606241 = body
  result = call_606239.call(path_606240, nil, nil, nil, body_606241)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_606226(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_606227, base: "/",
    url: url_CreateConfigurationSetEventDestination_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_606198 = ref object of OpenApiRestCall_605589
proc url_GetConfigurationSetEventDestinations_606200(protocol: Scheme;
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

proc validate_GetConfigurationSetEventDestinations_606199(path: JsonNode;
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
  var valid_606215 = path.getOrDefault("ConfigurationSetName")
  valid_606215 = validateParameter(valid_606215, JString, required = true,
                                 default = nil)
  if valid_606215 != nil:
    section.add "ConfigurationSetName", valid_606215
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
  var valid_606216 = header.getOrDefault("X-Amz-Signature")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Signature", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Content-Sha256", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Date")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Date", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Credential")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Credential", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Security-Token")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Security-Token", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Algorithm")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Algorithm", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-SignedHeaders", valid_606222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_GetConfigurationSetEventDestinations_606198;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_GetConfigurationSetEventDestinations_606198;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_606225 = newJObject()
  add(path_606225, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_606224.call(path_606225, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_606198(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_606199, base: "/",
    url: url_GetConfigurationSetEventDestinations_606200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDedicatedIpPool_606257 = ref object of OpenApiRestCall_605589
proc url_CreateDedicatedIpPool_606259(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDedicatedIpPool_606258(path: JsonNode; query: JsonNode;
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
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_CreateDedicatedIpPool_606257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_CreateDedicatedIpPool_606257; body: JsonNode): Recallable =
  ## createDedicatedIpPool
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var createDedicatedIpPool* = Call_CreateDedicatedIpPool_606257(
    name: "createDedicatedIpPool", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_CreateDedicatedIpPool_606258, base: "/",
    url: url_CreateDedicatedIpPool_606259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDedicatedIpPools_606242 = ref object of OpenApiRestCall_605589
proc url_ListDedicatedIpPools_606244(protocol: Scheme; host: string; base: string;
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

proc validate_ListDedicatedIpPools_606243(path: JsonNode; query: JsonNode;
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
  var valid_606245 = query.getOrDefault("NextToken")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "NextToken", valid_606245
  var valid_606246 = query.getOrDefault("PageSize")
  valid_606246 = validateParameter(valid_606246, JInt, required = false, default = nil)
  if valid_606246 != nil:
    section.add "PageSize", valid_606246
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
  var valid_606247 = header.getOrDefault("X-Amz-Signature")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Signature", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Content-Sha256", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Date")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Date", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Credential")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Credential", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Security-Token")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Security-Token", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Algorithm")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Algorithm", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-SignedHeaders", valid_606253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606254: Call_ListDedicatedIpPools_606242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_606254.validator(path, query, header, formData, body)
  let scheme = call_606254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606254.url(scheme.get, call_606254.host, call_606254.base,
                         call_606254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606254, url, valid)

proc call*(call_606255: Call_ListDedicatedIpPools_606242; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listDedicatedIpPools
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  var query_606256 = newJObject()
  add(query_606256, "NextToken", newJString(NextToken))
  add(query_606256, "PageSize", newJInt(PageSize))
  result = call_606255.call(nil, query_606256, nil, nil, nil)

var listDedicatedIpPools* = Call_ListDedicatedIpPools_606242(
    name: "listDedicatedIpPools", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_ListDedicatedIpPools_606243, base: "/",
    url: url_ListDedicatedIpPools_606244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeliverabilityTestReport_606271 = ref object of OpenApiRestCall_605589
proc url_CreateDeliverabilityTestReport_606273(protocol: Scheme; host: string;
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

proc validate_CreateDeliverabilityTestReport_606272(path: JsonNode;
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
  var valid_606274 = header.getOrDefault("X-Amz-Signature")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Signature", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Content-Sha256", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Date")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Date", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Credential")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Credential", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Security-Token")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Security-Token", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Algorithm")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Algorithm", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-SignedHeaders", valid_606280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606282: Call_CreateDeliverabilityTestReport_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  let valid = call_606282.validator(path, query, header, formData, body)
  let scheme = call_606282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606282.url(scheme.get, call_606282.host, call_606282.base,
                         call_606282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606282, url, valid)

proc call*(call_606283: Call_CreateDeliverabilityTestReport_606271; body: JsonNode): Recallable =
  ## createDeliverabilityTestReport
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ##   body: JObject (required)
  var body_606284 = newJObject()
  if body != nil:
    body_606284 = body
  result = call_606283.call(nil, nil, nil, nil, body_606284)

var createDeliverabilityTestReport* = Call_CreateDeliverabilityTestReport_606271(
    name: "createDeliverabilityTestReport", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/test",
    validator: validate_CreateDeliverabilityTestReport_606272, base: "/",
    url: url_CreateDeliverabilityTestReport_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailIdentity_606300 = ref object of OpenApiRestCall_605589
proc url_CreateEmailIdentity_606302(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEmailIdentity_606301(path: JsonNode; query: JsonNode;
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
  var valid_606303 = header.getOrDefault("X-Amz-Signature")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Signature", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Content-Sha256", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Date")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Date", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Credential")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Credential", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Security-Token")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Security-Token", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Algorithm")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Algorithm", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-SignedHeaders", valid_606309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606311: Call_CreateEmailIdentity_606300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ## 
  let valid = call_606311.validator(path, query, header, formData, body)
  let scheme = call_606311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606311.url(scheme.get, call_606311.host, call_606311.base,
                         call_606311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606311, url, valid)

proc call*(call_606312: Call_CreateEmailIdentity_606300; body: JsonNode): Recallable =
  ## createEmailIdentity
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ##   body: JObject (required)
  var body_606313 = newJObject()
  if body != nil:
    body_606313 = body
  result = call_606312.call(nil, nil, nil, nil, body_606313)

var createEmailIdentity* = Call_CreateEmailIdentity_606300(
    name: "createEmailIdentity", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_CreateEmailIdentity_606301, base: "/",
    url: url_CreateEmailIdentity_606302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEmailIdentities_606285 = ref object of OpenApiRestCall_605589
proc url_ListEmailIdentities_606287(protocol: Scheme; host: string; base: string;
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

proc validate_ListEmailIdentities_606286(path: JsonNode; query: JsonNode;
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
  var valid_606288 = query.getOrDefault("NextToken")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "NextToken", valid_606288
  var valid_606289 = query.getOrDefault("PageSize")
  valid_606289 = validateParameter(valid_606289, JInt, required = false, default = nil)
  if valid_606289 != nil:
    section.add "PageSize", valid_606289
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
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606297: Call_ListEmailIdentities_606285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ## 
  let valid = call_606297.validator(path, query, header, formData, body)
  let scheme = call_606297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606297.url(scheme.get, call_606297.host, call_606297.base,
                         call_606297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606297, url, valid)

proc call*(call_606298: Call_ListEmailIdentities_606285; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listEmailIdentities
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  var query_606299 = newJObject()
  add(query_606299, "NextToken", newJString(NextToken))
  add(query_606299, "PageSize", newJInt(PageSize))
  result = call_606298.call(nil, query_606299, nil, nil, nil)

var listEmailIdentities* = Call_ListEmailIdentities_606285(
    name: "listEmailIdentities", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_ListEmailIdentities_606286, base: "/",
    url: url_ListEmailIdentities_606287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSet_606314 = ref object of OpenApiRestCall_605589
proc url_GetConfigurationSet_606316(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfigurationSet_606315(path: JsonNode; query: JsonNode;
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
  var valid_606317 = path.getOrDefault("ConfigurationSetName")
  valid_606317 = validateParameter(valid_606317, JString, required = true,
                                 default = nil)
  if valid_606317 != nil:
    section.add "ConfigurationSetName", valid_606317
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
  var valid_606318 = header.getOrDefault("X-Amz-Signature")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Signature", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Content-Sha256", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Date")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Date", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Credential")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Credential", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Security-Token")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Security-Token", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Algorithm")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Algorithm", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-SignedHeaders", valid_606324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606325: Call_GetConfigurationSet_606314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_606325.validator(path, query, header, formData, body)
  let scheme = call_606325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606325.url(scheme.get, call_606325.host, call_606325.base,
                         call_606325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606325, url, valid)

proc call*(call_606326: Call_GetConfigurationSet_606314;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSet
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_606327 = newJObject()
  add(path_606327, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_606326.call(path_606327, nil, nil, nil, nil)

var getConfigurationSet* = Call_GetConfigurationSet_606314(
    name: "getConfigurationSet", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_GetConfigurationSet_606315, base: "/",
    url: url_GetConfigurationSet_606316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_606328 = ref object of OpenApiRestCall_605589
proc url_DeleteConfigurationSet_606330(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConfigurationSet_606329(path: JsonNode; query: JsonNode;
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
  var valid_606331 = path.getOrDefault("ConfigurationSetName")
  valid_606331 = validateParameter(valid_606331, JString, required = true,
                                 default = nil)
  if valid_606331 != nil:
    section.add "ConfigurationSetName", valid_606331
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
  var valid_606332 = header.getOrDefault("X-Amz-Signature")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Signature", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Content-Sha256", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Date")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Date", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Credential")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Credential", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Security-Token")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Security-Token", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Algorithm")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Algorithm", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-SignedHeaders", valid_606338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606339: Call_DeleteConfigurationSet_606328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_606339.validator(path, query, header, formData, body)
  let scheme = call_606339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606339.url(scheme.get, call_606339.host, call_606339.base,
                         call_606339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606339, url, valid)

proc call*(call_606340: Call_DeleteConfigurationSet_606328;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_606341 = newJObject()
  add(path_606341, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_606340.call(path_606341, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_606328(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_606329, base: "/",
    url: url_DeleteConfigurationSet_606330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_606342 = ref object of OpenApiRestCall_605589
proc url_UpdateConfigurationSetEventDestination_606344(protocol: Scheme;
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

proc validate_UpdateConfigurationSetEventDestination_606343(path: JsonNode;
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
  var valid_606345 = path.getOrDefault("ConfigurationSetName")
  valid_606345 = validateParameter(valid_606345, JString, required = true,
                                 default = nil)
  if valid_606345 != nil:
    section.add "ConfigurationSetName", valid_606345
  var valid_606346 = path.getOrDefault("EventDestinationName")
  valid_606346 = validateParameter(valid_606346, JString, required = true,
                                 default = nil)
  if valid_606346 != nil:
    section.add "EventDestinationName", valid_606346
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
  var valid_606347 = header.getOrDefault("X-Amz-Signature")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Signature", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Content-Sha256", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Date")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Date", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Credential")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Credential", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Security-Token")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Security-Token", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Algorithm")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Algorithm", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-SignedHeaders", valid_606353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606355: Call_UpdateConfigurationSetEventDestination_606342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_606355.validator(path, query, header, formData, body)
  let scheme = call_606355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606355.url(scheme.get, call_606355.host, call_606355.base,
                         call_606355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606355, url, valid)

proc call*(call_606356: Call_UpdateConfigurationSetEventDestination_606342;
          ConfigurationSetName: string; EventDestinationName: string; body: JsonNode): Recallable =
  ## updateConfigurationSetEventDestination
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   body: JObject (required)
  var path_606357 = newJObject()
  var body_606358 = newJObject()
  add(path_606357, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_606357, "EventDestinationName", newJString(EventDestinationName))
  if body != nil:
    body_606358 = body
  result = call_606356.call(path_606357, nil, nil, nil, body_606358)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_606342(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_606343, base: "/",
    url: url_UpdateConfigurationSetEventDestination_606344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_606359 = ref object of OpenApiRestCall_605589
proc url_DeleteConfigurationSetEventDestination_606361(protocol: Scheme;
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

proc validate_DeleteConfigurationSetEventDestination_606360(path: JsonNode;
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
  var valid_606362 = path.getOrDefault("ConfigurationSetName")
  valid_606362 = validateParameter(valid_606362, JString, required = true,
                                 default = nil)
  if valid_606362 != nil:
    section.add "ConfigurationSetName", valid_606362
  var valid_606363 = path.getOrDefault("EventDestinationName")
  valid_606363 = validateParameter(valid_606363, JString, required = true,
                                 default = nil)
  if valid_606363 != nil:
    section.add "EventDestinationName", valid_606363
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
  var valid_606364 = header.getOrDefault("X-Amz-Signature")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Signature", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Content-Sha256", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Date")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Date", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Credential")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Credential", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Security-Token")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Security-Token", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Algorithm")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Algorithm", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-SignedHeaders", valid_606370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606371: Call_DeleteConfigurationSetEventDestination_606359;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_606371.validator(path, query, header, formData, body)
  let scheme = call_606371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606371.url(scheme.get, call_606371.host, call_606371.base,
                         call_606371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606371, url, valid)

proc call*(call_606372: Call_DeleteConfigurationSetEventDestination_606359;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_606373 = newJObject()
  add(path_606373, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_606373, "EventDestinationName", newJString(EventDestinationName))
  result = call_606372.call(path_606373, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_606359(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_606360, base: "/",
    url: url_DeleteConfigurationSetEventDestination_606361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDedicatedIpPool_606374 = ref object of OpenApiRestCall_605589
proc url_DeleteDedicatedIpPool_606376(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDedicatedIpPool_606375(path: JsonNode; query: JsonNode;
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
  var valid_606377 = path.getOrDefault("PoolName")
  valid_606377 = validateParameter(valid_606377, JString, required = true,
                                 default = nil)
  if valid_606377 != nil:
    section.add "PoolName", valid_606377
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
  var valid_606378 = header.getOrDefault("X-Amz-Signature")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Signature", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Content-Sha256", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Date")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Date", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Credential")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Credential", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Security-Token")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Security-Token", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Algorithm")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Algorithm", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-SignedHeaders", valid_606384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606385: Call_DeleteDedicatedIpPool_606374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a dedicated IP pool.
  ## 
  let valid = call_606385.validator(path, query, header, formData, body)
  let scheme = call_606385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606385.url(scheme.get, call_606385.host, call_606385.base,
                         call_606385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606385, url, valid)

proc call*(call_606386: Call_DeleteDedicatedIpPool_606374; PoolName: string): Recallable =
  ## deleteDedicatedIpPool
  ## Delete a dedicated IP pool.
  ##   PoolName: string (required)
  ##           : The name of a dedicated IP pool.
  var path_606387 = newJObject()
  add(path_606387, "PoolName", newJString(PoolName))
  result = call_606386.call(path_606387, nil, nil, nil, nil)

var deleteDedicatedIpPool* = Call_DeleteDedicatedIpPool_606374(
    name: "deleteDedicatedIpPool", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools/{PoolName}",
    validator: validate_DeleteDedicatedIpPool_606375, base: "/",
    url: url_DeleteDedicatedIpPool_606376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailIdentity_606388 = ref object of OpenApiRestCall_605589
proc url_GetEmailIdentity_606390(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailIdentity_606389(path: JsonNode; query: JsonNode;
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
  var valid_606391 = path.getOrDefault("EmailIdentity")
  valid_606391 = validateParameter(valid_606391, JString, required = true,
                                 default = nil)
  if valid_606391 != nil:
    section.add "EmailIdentity", valid_606391
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
  var valid_606392 = header.getOrDefault("X-Amz-Signature")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Signature", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Content-Sha256", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Date")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Date", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Credential")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Credential", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Security-Token")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Security-Token", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Algorithm")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Algorithm", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-SignedHeaders", valid_606398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606399: Call_GetEmailIdentity_606388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  let valid = call_606399.validator(path, query, header, formData, body)
  let scheme = call_606399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606399.url(scheme.get, call_606399.host, call_606399.base,
                         call_606399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606399, url, valid)

proc call*(call_606400: Call_GetEmailIdentity_606388; EmailIdentity: string): Recallable =
  ## getEmailIdentity
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to retrieve details for.
  var path_606401 = newJObject()
  add(path_606401, "EmailIdentity", newJString(EmailIdentity))
  result = call_606400.call(path_606401, nil, nil, nil, nil)

var getEmailIdentity* = Call_GetEmailIdentity_606388(name: "getEmailIdentity",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_GetEmailIdentity_606389, base: "/",
    url: url_GetEmailIdentity_606390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailIdentity_606402 = ref object of OpenApiRestCall_605589
proc url_DeleteEmailIdentity_606404(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailIdentity_606403(path: JsonNode; query: JsonNode;
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
  var valid_606405 = path.getOrDefault("EmailIdentity")
  valid_606405 = validateParameter(valid_606405, JString, required = true,
                                 default = nil)
  if valid_606405 != nil:
    section.add "EmailIdentity", valid_606405
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
  var valid_606406 = header.getOrDefault("X-Amz-Signature")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Signature", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Content-Sha256", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Date")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Date", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Credential")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Credential", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Security-Token")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Security-Token", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Algorithm")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Algorithm", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-SignedHeaders", valid_606412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606413: Call_DeleteEmailIdentity_606402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ## 
  let valid = call_606413.validator(path, query, header, formData, body)
  let scheme = call_606413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606413.url(scheme.get, call_606413.host, call_606413.base,
                         call_606413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606413, url, valid)

proc call*(call_606414: Call_DeleteEmailIdentity_606402; EmailIdentity: string): Recallable =
  ## deleteEmailIdentity
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ##   EmailIdentity: string (required)
  ##                : The identity (that is, the email address or domain) that you want to delete from your Amazon Pinpoint account.
  var path_606415 = newJObject()
  add(path_606415, "EmailIdentity", newJString(EmailIdentity))
  result = call_606414.call(path_606415, nil, nil, nil, nil)

var deleteEmailIdentity* = Call_DeleteEmailIdentity_606402(
    name: "deleteEmailIdentity", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_DeleteEmailIdentity_606403, base: "/",
    url: url_DeleteEmailIdentity_606404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_606416 = ref object of OpenApiRestCall_605589
proc url_GetAccount_606418(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAccount_606417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606419 = header.getOrDefault("X-Amz-Signature")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Signature", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Content-Sha256", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Date")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Date", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Credential")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Credential", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Security-Token")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Security-Token", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Algorithm")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Algorithm", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-SignedHeaders", valid_606425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606426: Call_GetAccount_606416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_606426.validator(path, query, header, formData, body)
  let scheme = call_606426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606426.url(scheme.get, call_606426.host, call_606426.base,
                         call_606426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606426, url, valid)

proc call*(call_606427: Call_GetAccount_606416): Recallable =
  ## getAccount
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  result = call_606427.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_606416(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "email.amazonaws.com",
                                      route: "/v1/email/account",
                                      validator: validate_GetAccount_606417,
                                      base: "/", url: url_GetAccount_606418,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlacklistReports_606428 = ref object of OpenApiRestCall_605589
proc url_GetBlacklistReports_606430(protocol: Scheme; host: string; base: string;
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

proc validate_GetBlacklistReports_606429(path: JsonNode; query: JsonNode;
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
  var valid_606431 = query.getOrDefault("BlacklistItemNames")
  valid_606431 = validateParameter(valid_606431, JArray, required = true, default = nil)
  if valid_606431 != nil:
    section.add "BlacklistItemNames", valid_606431
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
  var valid_606432 = header.getOrDefault("X-Amz-Signature")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Signature", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Content-Sha256", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Date")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Date", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Credential")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Credential", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Security-Token")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Security-Token", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Algorithm")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Algorithm", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-SignedHeaders", valid_606438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606439: Call_GetBlacklistReports_606428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ## 
  let valid = call_606439.validator(path, query, header, formData, body)
  let scheme = call_606439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606439.url(scheme.get, call_606439.host, call_606439.base,
                         call_606439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606439, url, valid)

proc call*(call_606440: Call_GetBlacklistReports_606428;
          BlacklistItemNames: JsonNode): Recallable =
  ## getBlacklistReports
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ##   BlacklistItemNames: JArray (required)
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon Pinpoint or Amazon SES.
  var query_606441 = newJObject()
  if BlacklistItemNames != nil:
    query_606441.add "BlacklistItemNames", BlacklistItemNames
  result = call_606440.call(nil, query_606441, nil, nil, nil)

var getBlacklistReports* = Call_GetBlacklistReports_606428(
    name: "getBlacklistReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/blacklist-report#BlacklistItemNames",
    validator: validate_GetBlacklistReports_606429, base: "/",
    url: url_GetBlacklistReports_606430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIp_606442 = ref object of OpenApiRestCall_605589
proc url_GetDedicatedIp_606444(protocol: Scheme; host: string; base: string;
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

proc validate_GetDedicatedIp_606443(path: JsonNode; query: JsonNode;
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
  var valid_606445 = path.getOrDefault("IP")
  valid_606445 = validateParameter(valid_606445, JString, required = true,
                                 default = nil)
  if valid_606445 != nil:
    section.add "IP", valid_606445
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
  var valid_606446 = header.getOrDefault("X-Amz-Signature")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Signature", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Content-Sha256", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Date")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Date", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Credential")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Credential", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Security-Token")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Security-Token", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Algorithm")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Algorithm", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-SignedHeaders", valid_606452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606453: Call_GetDedicatedIp_606442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  let valid = call_606453.validator(path, query, header, formData, body)
  let scheme = call_606453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606453.url(scheme.get, call_606453.host, call_606453.base,
                         call_606453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606453, url, valid)

proc call*(call_606454: Call_GetDedicatedIp_606442; IP: string): Recallable =
  ## getDedicatedIp
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  var path_606455 = newJObject()
  add(path_606455, "IP", newJString(IP))
  result = call_606454.call(path_606455, nil, nil, nil, nil)

var getDedicatedIp* = Call_GetDedicatedIp_606442(name: "getDedicatedIp",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips/{IP}", validator: validate_GetDedicatedIp_606443,
    base: "/", url: url_GetDedicatedIp_606444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIps_606456 = ref object of OpenApiRestCall_605589
proc url_GetDedicatedIps_606458(protocol: Scheme; host: string; base: string;
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

proc validate_GetDedicatedIps_606457(path: JsonNode; query: JsonNode;
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
  var valid_606459 = query.getOrDefault("NextToken")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "NextToken", valid_606459
  var valid_606460 = query.getOrDefault("PageSize")
  valid_606460 = validateParameter(valid_606460, JInt, required = false, default = nil)
  if valid_606460 != nil:
    section.add "PageSize", valid_606460
  var valid_606461 = query.getOrDefault("PoolName")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "PoolName", valid_606461
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
  var valid_606462 = header.getOrDefault("X-Amz-Signature")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Signature", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Content-Sha256", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Date")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Date", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Credential")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Credential", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Security-Token")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Security-Token", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Algorithm")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Algorithm", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-SignedHeaders", valid_606468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606469: Call_GetDedicatedIps_606456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_606469.validator(path, query, header, formData, body)
  let scheme = call_606469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606469.url(scheme.get, call_606469.host, call_606469.base,
                         call_606469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606469, url, valid)

proc call*(call_606470: Call_GetDedicatedIps_606456; NextToken: string = "";
          PageSize: int = 0; PoolName: string = ""): Recallable =
  ## getDedicatedIps
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   PoolName: string
  ##           : The name of a dedicated IP pool.
  var query_606471 = newJObject()
  add(query_606471, "NextToken", newJString(NextToken))
  add(query_606471, "PageSize", newJInt(PageSize))
  add(query_606471, "PoolName", newJString(PoolName))
  result = call_606470.call(nil, query_606471, nil, nil, nil)

var getDedicatedIps* = Call_GetDedicatedIps_606456(name: "getDedicatedIps",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips", validator: validate_GetDedicatedIps_606457,
    base: "/", url: url_GetDedicatedIps_606458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliverabilityDashboardOption_606484 = ref object of OpenApiRestCall_605589
proc url_PutDeliverabilityDashboardOption_606486(protocol: Scheme; host: string;
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

proc validate_PutDeliverabilityDashboardOption_606485(path: JsonNode;
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
  var valid_606487 = header.getOrDefault("X-Amz-Signature")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Signature", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Content-Sha256", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Date")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Date", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Credential")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Credential", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Security-Token")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Security-Token", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Algorithm")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Algorithm", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-SignedHeaders", valid_606493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606495: Call_PutDeliverabilityDashboardOption_606484;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_606495.validator(path, query, header, formData, body)
  let scheme = call_606495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606495.url(scheme.get, call_606495.host, call_606495.base,
                         call_606495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606495, url, valid)

proc call*(call_606496: Call_PutDeliverabilityDashboardOption_606484;
          body: JsonNode): Recallable =
  ## putDeliverabilityDashboardOption
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ##   body: JObject (required)
  var body_606497 = newJObject()
  if body != nil:
    body_606497 = body
  result = call_606496.call(nil, nil, nil, nil, body_606497)

var putDeliverabilityDashboardOption* = Call_PutDeliverabilityDashboardOption_606484(
    name: "putDeliverabilityDashboardOption", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_PutDeliverabilityDashboardOption_606485, base: "/",
    url: url_PutDeliverabilityDashboardOption_606486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityDashboardOptions_606472 = ref object of OpenApiRestCall_605589
proc url_GetDeliverabilityDashboardOptions_606474(protocol: Scheme; host: string;
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

proc validate_GetDeliverabilityDashboardOptions_606473(path: JsonNode;
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
  var valid_606475 = header.getOrDefault("X-Amz-Signature")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Signature", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Content-Sha256", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Date")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Date", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Credential")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Credential", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Security-Token")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Security-Token", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Algorithm")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Algorithm", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-SignedHeaders", valid_606481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606482: Call_GetDeliverabilityDashboardOptions_606472;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_606482.validator(path, query, header, formData, body)
  let scheme = call_606482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606482.url(scheme.get, call_606482.host, call_606482.base,
                         call_606482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606482, url, valid)

proc call*(call_606483: Call_GetDeliverabilityDashboardOptions_606472): Recallable =
  ## getDeliverabilityDashboardOptions
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  result = call_606483.call(nil, nil, nil, nil, nil)

var getDeliverabilityDashboardOptions* = Call_GetDeliverabilityDashboardOptions_606472(
    name: "getDeliverabilityDashboardOptions", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_GetDeliverabilityDashboardOptions_606473, base: "/",
    url: url_GetDeliverabilityDashboardOptions_606474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityTestReport_606498 = ref object of OpenApiRestCall_605589
proc url_GetDeliverabilityTestReport_606500(protocol: Scheme; host: string;
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

proc validate_GetDeliverabilityTestReport_606499(path: JsonNode; query: JsonNode;
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
  var valid_606501 = path.getOrDefault("ReportId")
  valid_606501 = validateParameter(valid_606501, JString, required = true,
                                 default = nil)
  if valid_606501 != nil:
    section.add "ReportId", valid_606501
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
  var valid_606502 = header.getOrDefault("X-Amz-Signature")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Signature", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Content-Sha256", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Date")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Date", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Credential")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Credential", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Security-Token")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Security-Token", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Algorithm")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Algorithm", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-SignedHeaders", valid_606508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606509: Call_GetDeliverabilityTestReport_606498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  let valid = call_606509.validator(path, query, header, formData, body)
  let scheme = call_606509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606509.url(scheme.get, call_606509.host, call_606509.base,
                         call_606509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606509, url, valid)

proc call*(call_606510: Call_GetDeliverabilityTestReport_606498; ReportId: string): Recallable =
  ## getDeliverabilityTestReport
  ## Retrieve the results of a predictive inbox placement test.
  ##   ReportId: string (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  var path_606511 = newJObject()
  add(path_606511, "ReportId", newJString(ReportId))
  result = call_606510.call(path_606511, nil, nil, nil, nil)

var getDeliverabilityTestReport* = Call_GetDeliverabilityTestReport_606498(
    name: "getDeliverabilityTestReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports/{ReportId}",
    validator: validate_GetDeliverabilityTestReport_606499, base: "/",
    url: url_GetDeliverabilityTestReport_606500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDeliverabilityCampaign_606512 = ref object of OpenApiRestCall_605589
proc url_GetDomainDeliverabilityCampaign_606514(protocol: Scheme; host: string;
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

proc validate_GetDomainDeliverabilityCampaign_606513(path: JsonNode;
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
  var valid_606515 = path.getOrDefault("CampaignId")
  valid_606515 = validateParameter(valid_606515, JString, required = true,
                                 default = nil)
  if valid_606515 != nil:
    section.add "CampaignId", valid_606515
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
  var valid_606516 = header.getOrDefault("X-Amz-Signature")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Signature", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Content-Sha256", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Date")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Date", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Credential")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Credential", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Security-Token")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Security-Token", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Algorithm")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Algorithm", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-SignedHeaders", valid_606522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_GetDomainDeliverabilityCampaign_606512;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_GetDomainDeliverabilityCampaign_606512;
          CampaignId: string): Recallable =
  ## getDomainDeliverabilityCampaign
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ##   CampaignId: string (required)
  ##             : The unique identifier for the campaign. Amazon Pinpoint automatically generates and assigns this identifier to a campaign. This value is not the same as the campaign identifier that Amazon Pinpoint assigns to campaigns that you create and manage by using the Amazon Pinpoint API or the Amazon Pinpoint console.
  var path_606525 = newJObject()
  add(path_606525, "CampaignId", newJString(CampaignId))
  result = call_606524.call(path_606525, nil, nil, nil, nil)

var getDomainDeliverabilityCampaign* = Call_GetDomainDeliverabilityCampaign_606512(
    name: "getDomainDeliverabilityCampaign", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/campaigns/{CampaignId}",
    validator: validate_GetDomainDeliverabilityCampaign_606513, base: "/",
    url: url_GetDomainDeliverabilityCampaign_606514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainStatisticsReport_606526 = ref object of OpenApiRestCall_605589
proc url_GetDomainStatisticsReport_606528(protocol: Scheme; host: string;
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

proc validate_GetDomainStatisticsReport_606527(path: JsonNode; query: JsonNode;
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
  var valid_606529 = path.getOrDefault("Domain")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = nil)
  if valid_606529 != nil:
    section.add "Domain", valid_606529
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: JString (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_606530 = query.getOrDefault("EndDate")
  valid_606530 = validateParameter(valid_606530, JString, required = true,
                                 default = nil)
  if valid_606530 != nil:
    section.add "EndDate", valid_606530
  var valid_606531 = query.getOrDefault("StartDate")
  valid_606531 = validateParameter(valid_606531, JString, required = true,
                                 default = nil)
  if valid_606531 != nil:
    section.add "StartDate", valid_606531
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
  var valid_606532 = header.getOrDefault("X-Amz-Signature")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Signature", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Content-Sha256", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Date")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Date", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Credential")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Credential", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Security-Token")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Security-Token", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Algorithm")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Algorithm", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-SignedHeaders", valid_606538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606539: Call_GetDomainStatisticsReport_606526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  let valid = call_606539.validator(path, query, header, formData, body)
  let scheme = call_606539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606539.url(scheme.get, call_606539.host, call_606539.base,
                         call_606539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606539, url, valid)

proc call*(call_606540: Call_GetDomainStatisticsReport_606526; EndDate: string;
          Domain: string; StartDate: string): Recallable =
  ## getDomainStatisticsReport
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ##   EndDate: string (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   Domain: string (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  ##   StartDate: string (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  var path_606541 = newJObject()
  var query_606542 = newJObject()
  add(query_606542, "EndDate", newJString(EndDate))
  add(path_606541, "Domain", newJString(Domain))
  add(query_606542, "StartDate", newJString(StartDate))
  result = call_606540.call(path_606541, query_606542, nil, nil, nil)

var getDomainStatisticsReport* = Call_GetDomainStatisticsReport_606526(
    name: "getDomainStatisticsReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/statistics-report/{Domain}#StartDate&EndDate",
    validator: validate_GetDomainStatisticsReport_606527, base: "/",
    url: url_GetDomainStatisticsReport_606528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeliverabilityTestReports_606543 = ref object of OpenApiRestCall_605589
proc url_ListDeliverabilityTestReports_606545(protocol: Scheme; host: string;
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

proc validate_ListDeliverabilityTestReports_606544(path: JsonNode; query: JsonNode;
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
  var valid_606546 = query.getOrDefault("NextToken")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "NextToken", valid_606546
  var valid_606547 = query.getOrDefault("PageSize")
  valid_606547 = validateParameter(valid_606547, JInt, required = false, default = nil)
  if valid_606547 != nil:
    section.add "PageSize", valid_606547
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
  var valid_606548 = header.getOrDefault("X-Amz-Signature")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Signature", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Content-Sha256", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Date")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Date", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Credential")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Credential", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Security-Token")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Security-Token", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Algorithm")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Algorithm", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-SignedHeaders", valid_606554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606555: Call_ListDeliverabilityTestReports_606543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  let valid = call_606555.validator(path, query, header, formData, body)
  let scheme = call_606555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606555.url(scheme.get, call_606555.host, call_606555.base,
                         call_606555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606555, url, valid)

proc call*(call_606556: Call_ListDeliverabilityTestReports_606543;
          NextToken: string = ""; PageSize: int = 0): Recallable =
  ## listDeliverabilityTestReports
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  var query_606557 = newJObject()
  add(query_606557, "NextToken", newJString(NextToken))
  add(query_606557, "PageSize", newJInt(PageSize))
  result = call_606556.call(nil, query_606557, nil, nil, nil)

var listDeliverabilityTestReports* = Call_ListDeliverabilityTestReports_606543(
    name: "listDeliverabilityTestReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports",
    validator: validate_ListDeliverabilityTestReports_606544, base: "/",
    url: url_ListDeliverabilityTestReports_606545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainDeliverabilityCampaigns_606558 = ref object of OpenApiRestCall_605589
proc url_ListDomainDeliverabilityCampaigns_606560(protocol: Scheme; host: string;
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

proc validate_ListDomainDeliverabilityCampaigns_606559(path: JsonNode;
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
  var valid_606561 = path.getOrDefault("SubscribedDomain")
  valid_606561 = validateParameter(valid_606561, JString, required = true,
                                 default = nil)
  if valid_606561 != nil:
    section.add "SubscribedDomain", valid_606561
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
  var valid_606562 = query.getOrDefault("EndDate")
  valid_606562 = validateParameter(valid_606562, JString, required = true,
                                 default = nil)
  if valid_606562 != nil:
    section.add "EndDate", valid_606562
  var valid_606563 = query.getOrDefault("NextToken")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "NextToken", valid_606563
  var valid_606564 = query.getOrDefault("PageSize")
  valid_606564 = validateParameter(valid_606564, JInt, required = false, default = nil)
  if valid_606564 != nil:
    section.add "PageSize", valid_606564
  var valid_606565 = query.getOrDefault("StartDate")
  valid_606565 = validateParameter(valid_606565, JString, required = true,
                                 default = nil)
  if valid_606565 != nil:
    section.add "StartDate", valid_606565
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
  var valid_606566 = header.getOrDefault("X-Amz-Signature")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Signature", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Content-Sha256", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Date")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Date", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Credential")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Credential", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Security-Token")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Security-Token", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Algorithm")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Algorithm", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-SignedHeaders", valid_606572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606573: Call_ListDomainDeliverabilityCampaigns_606558;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ## 
  let valid = call_606573.validator(path, query, header, formData, body)
  let scheme = call_606573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606573.url(scheme.get, call_606573.host, call_606573.base,
                         call_606573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606573, url, valid)

proc call*(call_606574: Call_ListDomainDeliverabilityCampaigns_606558;
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
  var path_606575 = newJObject()
  var query_606576 = newJObject()
  add(query_606576, "EndDate", newJString(EndDate))
  add(query_606576, "NextToken", newJString(NextToken))
  add(path_606575, "SubscribedDomain", newJString(SubscribedDomain))
  add(query_606576, "PageSize", newJInt(PageSize))
  add(query_606576, "StartDate", newJString(StartDate))
  result = call_606574.call(path_606575, query_606576, nil, nil, nil)

var listDomainDeliverabilityCampaigns* = Call_ListDomainDeliverabilityCampaigns_606558(
    name: "listDomainDeliverabilityCampaigns", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/domains/{SubscribedDomain}/campaigns#StartDate&EndDate",
    validator: validate_ListDomainDeliverabilityCampaigns_606559, base: "/",
    url: url_ListDomainDeliverabilityCampaigns_606560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606577 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606579(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606578(path: JsonNode; query: JsonNode;
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
  var valid_606580 = query.getOrDefault("ResourceArn")
  valid_606580 = validateParameter(valid_606580, JString, required = true,
                                 default = nil)
  if valid_606580 != nil:
    section.add "ResourceArn", valid_606580
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
  var valid_606581 = header.getOrDefault("X-Amz-Signature")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Signature", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Content-Sha256", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Date")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Date", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Credential")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Credential", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Security-Token")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Security-Token", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Algorithm")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Algorithm", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-SignedHeaders", valid_606587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606588: Call_ListTagsForResource_606577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  let valid = call_606588.validator(path, query, header, formData, body)
  let scheme = call_606588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606588.url(scheme.get, call_606588.host, call_606588.base,
                         call_606588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606588, url, valid)

proc call*(call_606589: Call_ListTagsForResource_606577; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  var query_606590 = newJObject()
  add(query_606590, "ResourceArn", newJString(ResourceArn))
  result = call_606589.call(nil, query_606590, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606577(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/tags#ResourceArn",
    validator: validate_ListTagsForResource_606578, base: "/",
    url: url_ListTagsForResource_606579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountDedicatedIpWarmupAttributes_606591 = ref object of OpenApiRestCall_605589
proc url_PutAccountDedicatedIpWarmupAttributes_606593(protocol: Scheme;
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

proc validate_PutAccountDedicatedIpWarmupAttributes_606592(path: JsonNode;
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
  var valid_606594 = header.getOrDefault("X-Amz-Signature")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Signature", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Content-Sha256", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Date")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Date", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Credential")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Credential", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Security-Token")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Security-Token", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Algorithm")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Algorithm", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-SignedHeaders", valid_606600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606602: Call_PutAccountDedicatedIpWarmupAttributes_606591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ## 
  let valid = call_606602.validator(path, query, header, formData, body)
  let scheme = call_606602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606602.url(scheme.get, call_606602.host, call_606602.base,
                         call_606602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606602, url, valid)

proc call*(call_606603: Call_PutAccountDedicatedIpWarmupAttributes_606591;
          body: JsonNode): Recallable =
  ## putAccountDedicatedIpWarmupAttributes
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ##   body: JObject (required)
  var body_606604 = newJObject()
  if body != nil:
    body_606604 = body
  result = call_606603.call(nil, nil, nil, nil, body_606604)

var putAccountDedicatedIpWarmupAttributes* = Call_PutAccountDedicatedIpWarmupAttributes_606591(
    name: "putAccountDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/dedicated-ips/warmup",
    validator: validate_PutAccountDedicatedIpWarmupAttributes_606592, base: "/",
    url: url_PutAccountDedicatedIpWarmupAttributes_606593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSendingAttributes_606605 = ref object of OpenApiRestCall_605589
proc url_PutAccountSendingAttributes_606607(protocol: Scheme; host: string;
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

proc validate_PutAccountSendingAttributes_606606(path: JsonNode; query: JsonNode;
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
  var valid_606608 = header.getOrDefault("X-Amz-Signature")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Signature", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Content-Sha256", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Date")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Date", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Credential")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Credential", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Security-Token")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Security-Token", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Algorithm")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Algorithm", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-SignedHeaders", valid_606614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606616: Call_PutAccountSendingAttributes_606605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enable or disable the ability of your account to send email.
  ## 
  let valid = call_606616.validator(path, query, header, formData, body)
  let scheme = call_606616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606616.url(scheme.get, call_606616.host, call_606616.base,
                         call_606616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606616, url, valid)

proc call*(call_606617: Call_PutAccountSendingAttributes_606605; body: JsonNode): Recallable =
  ## putAccountSendingAttributes
  ## Enable or disable the ability of your account to send email.
  ##   body: JObject (required)
  var body_606618 = newJObject()
  if body != nil:
    body_606618 = body
  result = call_606617.call(nil, nil, nil, nil, body_606618)

var putAccountSendingAttributes* = Call_PutAccountSendingAttributes_606605(
    name: "putAccountSendingAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/sending",
    validator: validate_PutAccountSendingAttributes_606606, base: "/",
    url: url_PutAccountSendingAttributes_606607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetDeliveryOptions_606619 = ref object of OpenApiRestCall_605589
proc url_PutConfigurationSetDeliveryOptions_606621(protocol: Scheme; host: string;
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

proc validate_PutConfigurationSetDeliveryOptions_606620(path: JsonNode;
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
  var valid_606622 = path.getOrDefault("ConfigurationSetName")
  valid_606622 = validateParameter(valid_606622, JString, required = true,
                                 default = nil)
  if valid_606622 != nil:
    section.add "ConfigurationSetName", valid_606622
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
  var valid_606623 = header.getOrDefault("X-Amz-Signature")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Signature", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Content-Sha256", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Date")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Date", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Credential")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Credential", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Security-Token")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Security-Token", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Algorithm")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Algorithm", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-SignedHeaders", valid_606629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606631: Call_PutConfigurationSetDeliveryOptions_606619;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  let valid = call_606631.validator(path, query, header, formData, body)
  let scheme = call_606631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606631.url(scheme.get, call_606631.host, call_606631.base,
                         call_606631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606631, url, valid)

proc call*(call_606632: Call_PutConfigurationSetDeliveryOptions_606619;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetDeliveryOptions
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_606633 = newJObject()
  var body_606634 = newJObject()
  add(path_606633, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_606634 = body
  result = call_606632.call(path_606633, nil, nil, nil, body_606634)

var putConfigurationSetDeliveryOptions* = Call_PutConfigurationSetDeliveryOptions_606619(
    name: "putConfigurationSetDeliveryOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/delivery-options",
    validator: validate_PutConfigurationSetDeliveryOptions_606620, base: "/",
    url: url_PutConfigurationSetDeliveryOptions_606621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetReputationOptions_606635 = ref object of OpenApiRestCall_605589
proc url_PutConfigurationSetReputationOptions_606637(protocol: Scheme;
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

proc validate_PutConfigurationSetReputationOptions_606636(path: JsonNode;
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
  var valid_606638 = path.getOrDefault("ConfigurationSetName")
  valid_606638 = validateParameter(valid_606638, JString, required = true,
                                 default = nil)
  if valid_606638 != nil:
    section.add "ConfigurationSetName", valid_606638
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
  var valid_606639 = header.getOrDefault("X-Amz-Signature")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Signature", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Content-Sha256", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Date")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Date", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Credential")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Credential", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Security-Token")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Security-Token", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Algorithm")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Algorithm", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-SignedHeaders", valid_606645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606647: Call_PutConfigurationSetReputationOptions_606635;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_606647.validator(path, query, header, formData, body)
  let scheme = call_606647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606647.url(scheme.get, call_606647.host, call_606647.base,
                         call_606647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606647, url, valid)

proc call*(call_606648: Call_PutConfigurationSetReputationOptions_606635;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetReputationOptions
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_606649 = newJObject()
  var body_606650 = newJObject()
  add(path_606649, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_606650 = body
  result = call_606648.call(path_606649, nil, nil, nil, body_606650)

var putConfigurationSetReputationOptions* = Call_PutConfigurationSetReputationOptions_606635(
    name: "putConfigurationSetReputationOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/reputation-options",
    validator: validate_PutConfigurationSetReputationOptions_606636, base: "/",
    url: url_PutConfigurationSetReputationOptions_606637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSendingOptions_606651 = ref object of OpenApiRestCall_605589
proc url_PutConfigurationSetSendingOptions_606653(protocol: Scheme; host: string;
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

proc validate_PutConfigurationSetSendingOptions_606652(path: JsonNode;
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
  var valid_606654 = path.getOrDefault("ConfigurationSetName")
  valid_606654 = validateParameter(valid_606654, JString, required = true,
                                 default = nil)
  if valid_606654 != nil:
    section.add "ConfigurationSetName", valid_606654
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
  var valid_606655 = header.getOrDefault("X-Amz-Signature")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Signature", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Content-Sha256", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Date")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Date", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Credential")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Credential", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Security-Token")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Security-Token", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Algorithm")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Algorithm", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-SignedHeaders", valid_606661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606663: Call_PutConfigurationSetSendingOptions_606651;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_606663.validator(path, query, header, formData, body)
  let scheme = call_606663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606663.url(scheme.get, call_606663.host, call_606663.base,
                         call_606663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606663, url, valid)

proc call*(call_606664: Call_PutConfigurationSetSendingOptions_606651;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSendingOptions
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_606665 = newJObject()
  var body_606666 = newJObject()
  add(path_606665, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_606666 = body
  result = call_606664.call(path_606665, nil, nil, nil, body_606666)

var putConfigurationSetSendingOptions* = Call_PutConfigurationSetSendingOptions_606651(
    name: "putConfigurationSetSendingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}/sending",
    validator: validate_PutConfigurationSetSendingOptions_606652, base: "/",
    url: url_PutConfigurationSetSendingOptions_606653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetTrackingOptions_606667 = ref object of OpenApiRestCall_605589
proc url_PutConfigurationSetTrackingOptions_606669(protocol: Scheme; host: string;
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

proc validate_PutConfigurationSetTrackingOptions_606668(path: JsonNode;
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
  var valid_606670 = path.getOrDefault("ConfigurationSetName")
  valid_606670 = validateParameter(valid_606670, JString, required = true,
                                 default = nil)
  if valid_606670 != nil:
    section.add "ConfigurationSetName", valid_606670
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
  var valid_606671 = header.getOrDefault("X-Amz-Signature")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Signature", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Content-Sha256", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Date")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Date", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Credential")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Credential", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Security-Token")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Security-Token", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Algorithm")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Algorithm", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-SignedHeaders", valid_606677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606679: Call_PutConfigurationSetTrackingOptions_606667;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ## 
  let valid = call_606679.validator(path, query, header, formData, body)
  let scheme = call_606679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606679.url(scheme.get, call_606679.host, call_606679.base,
                         call_606679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606679, url, valid)

proc call*(call_606680: Call_PutConfigurationSetTrackingOptions_606667;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetTrackingOptions
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_606681 = newJObject()
  var body_606682 = newJObject()
  add(path_606681, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_606682 = body
  result = call_606680.call(path_606681, nil, nil, nil, body_606682)

var putConfigurationSetTrackingOptions* = Call_PutConfigurationSetTrackingOptions_606667(
    name: "putConfigurationSetTrackingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/tracking-options",
    validator: validate_PutConfigurationSetTrackingOptions_606668, base: "/",
    url: url_PutConfigurationSetTrackingOptions_606669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpInPool_606683 = ref object of OpenApiRestCall_605589
proc url_PutDedicatedIpInPool_606685(protocol: Scheme; host: string; base: string;
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

proc validate_PutDedicatedIpInPool_606684(path: JsonNode; query: JsonNode;
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
  var valid_606686 = path.getOrDefault("IP")
  valid_606686 = validateParameter(valid_606686, JString, required = true,
                                 default = nil)
  if valid_606686 != nil:
    section.add "IP", valid_606686
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
  var valid_606687 = header.getOrDefault("X-Amz-Signature")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Signature", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Content-Sha256", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Date")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Date", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Credential")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Credential", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Security-Token")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Security-Token", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Algorithm")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Algorithm", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-SignedHeaders", valid_606693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606695: Call_PutDedicatedIpInPool_606683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  let valid = call_606695.validator(path, query, header, formData, body)
  let scheme = call_606695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606695.url(scheme.get, call_606695.host, call_606695.base,
                         call_606695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606695, url, valid)

proc call*(call_606696: Call_PutDedicatedIpInPool_606683; IP: string; body: JsonNode): Recallable =
  ## putDedicatedIpInPool
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_606697 = newJObject()
  var body_606698 = newJObject()
  add(path_606697, "IP", newJString(IP))
  if body != nil:
    body_606698 = body
  result = call_606696.call(path_606697, nil, nil, nil, body_606698)

var putDedicatedIpInPool* = Call_PutDedicatedIpInPool_606683(
    name: "putDedicatedIpInPool", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/pool",
    validator: validate_PutDedicatedIpInPool_606684, base: "/",
    url: url_PutDedicatedIpInPool_606685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpWarmupAttributes_606699 = ref object of OpenApiRestCall_605589
proc url_PutDedicatedIpWarmupAttributes_606701(protocol: Scheme; host: string;
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

proc validate_PutDedicatedIpWarmupAttributes_606700(path: JsonNode;
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
  var valid_606702 = path.getOrDefault("IP")
  valid_606702 = validateParameter(valid_606702, JString, required = true,
                                 default = nil)
  if valid_606702 != nil:
    section.add "IP", valid_606702
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
  var valid_606703 = header.getOrDefault("X-Amz-Signature")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Signature", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Content-Sha256", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Date")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Date", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Credential")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Credential", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Security-Token")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Security-Token", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Algorithm")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Algorithm", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-SignedHeaders", valid_606709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606711: Call_PutDedicatedIpWarmupAttributes_606699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_606711.validator(path, query, header, formData, body)
  let scheme = call_606711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606711.url(scheme.get, call_606711.host, call_606711.base,
                         call_606711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606711, url, valid)

proc call*(call_606712: Call_PutDedicatedIpWarmupAttributes_606699; IP: string;
          body: JsonNode): Recallable =
  ## putDedicatedIpWarmupAttributes
  ## <p/>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_606713 = newJObject()
  var body_606714 = newJObject()
  add(path_606713, "IP", newJString(IP))
  if body != nil:
    body_606714 = body
  result = call_606712.call(path_606713, nil, nil, nil, body_606714)

var putDedicatedIpWarmupAttributes* = Call_PutDedicatedIpWarmupAttributes_606699(
    name: "putDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/warmup",
    validator: validate_PutDedicatedIpWarmupAttributes_606700, base: "/",
    url: url_PutDedicatedIpWarmupAttributes_606701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimAttributes_606715 = ref object of OpenApiRestCall_605589
proc url_PutEmailIdentityDkimAttributes_606717(protocol: Scheme; host: string;
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

proc validate_PutEmailIdentityDkimAttributes_606716(path: JsonNode;
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
  var valid_606718 = path.getOrDefault("EmailIdentity")
  valid_606718 = validateParameter(valid_606718, JString, required = true,
                                 default = nil)
  if valid_606718 != nil:
    section.add "EmailIdentity", valid_606718
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
  var valid_606719 = header.getOrDefault("X-Amz-Signature")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Signature", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Content-Sha256", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Date")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Date", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Credential")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Credential", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Security-Token")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Security-Token", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Algorithm")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Algorithm", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-SignedHeaders", valid_606725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606727: Call_PutEmailIdentityDkimAttributes_606715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to enable or disable DKIM authentication for an email identity.
  ## 
  let valid = call_606727.validator(path, query, header, formData, body)
  let scheme = call_606727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606727.url(scheme.get, call_606727.host, call_606727.base,
                         call_606727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606727, url, valid)

proc call*(call_606728: Call_PutEmailIdentityDkimAttributes_606715;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityDkimAttributes
  ## Used to enable or disable DKIM authentication for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to change the DKIM settings for.
  ##   body: JObject (required)
  var path_606729 = newJObject()
  var body_606730 = newJObject()
  add(path_606729, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_606730 = body
  result = call_606728.call(path_606729, nil, nil, nil, body_606730)

var putEmailIdentityDkimAttributes* = Call_PutEmailIdentityDkimAttributes_606715(
    name: "putEmailIdentityDkimAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/dkim",
    validator: validate_PutEmailIdentityDkimAttributes_606716, base: "/",
    url: url_PutEmailIdentityDkimAttributes_606717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityFeedbackAttributes_606731 = ref object of OpenApiRestCall_605589
proc url_PutEmailIdentityFeedbackAttributes_606733(protocol: Scheme; host: string;
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

proc validate_PutEmailIdentityFeedbackAttributes_606732(path: JsonNode;
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
  var valid_606734 = path.getOrDefault("EmailIdentity")
  valid_606734 = validateParameter(valid_606734, JString, required = true,
                                 default = nil)
  if valid_606734 != nil:
    section.add "EmailIdentity", valid_606734
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
  var valid_606735 = header.getOrDefault("X-Amz-Signature")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Signature", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Content-Sha256", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Date")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Date", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Credential")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Credential", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Security-Token")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Security-Token", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Algorithm")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Algorithm", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-SignedHeaders", valid_606741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606743: Call_PutEmailIdentityFeedbackAttributes_606731;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  let valid = call_606743.validator(path, query, header, formData, body)
  let scheme = call_606743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606743.url(scheme.get, call_606743.host, call_606743.base,
                         call_606743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606743, url, valid)

proc call*(call_606744: Call_PutEmailIdentityFeedbackAttributes_606731;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityFeedbackAttributes
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  ##   body: JObject (required)
  var path_606745 = newJObject()
  var body_606746 = newJObject()
  add(path_606745, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_606746 = body
  result = call_606744.call(path_606745, nil, nil, nil, body_606746)

var putEmailIdentityFeedbackAttributes* = Call_PutEmailIdentityFeedbackAttributes_606731(
    name: "putEmailIdentityFeedbackAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/feedback",
    validator: validate_PutEmailIdentityFeedbackAttributes_606732, base: "/",
    url: url_PutEmailIdentityFeedbackAttributes_606733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityMailFromAttributes_606747 = ref object of OpenApiRestCall_605589
proc url_PutEmailIdentityMailFromAttributes_606749(protocol: Scheme; host: string;
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

proc validate_PutEmailIdentityMailFromAttributes_606748(path: JsonNode;
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
  var valid_606750 = path.getOrDefault("EmailIdentity")
  valid_606750 = validateParameter(valid_606750, JString, required = true,
                                 default = nil)
  if valid_606750 != nil:
    section.add "EmailIdentity", valid_606750
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
  var valid_606751 = header.getOrDefault("X-Amz-Signature")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Signature", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Content-Sha256", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Date")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Date", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Credential")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Credential", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Security-Token")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Security-Token", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Algorithm")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Algorithm", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-SignedHeaders", valid_606757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606759: Call_PutEmailIdentityMailFromAttributes_606747;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ## 
  let valid = call_606759.validator(path, query, header, formData, body)
  let scheme = call_606759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606759.url(scheme.get, call_606759.host, call_606759.base,
                         call_606759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606759, url, valid)

proc call*(call_606760: Call_PutEmailIdentityMailFromAttributes_606747;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityMailFromAttributes
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  ##   body: JObject (required)
  var path_606761 = newJObject()
  var body_606762 = newJObject()
  add(path_606761, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_606762 = body
  result = call_606760.call(path_606761, nil, nil, nil, body_606762)

var putEmailIdentityMailFromAttributes* = Call_PutEmailIdentityMailFromAttributes_606747(
    name: "putEmailIdentityMailFromAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/mail-from",
    validator: validate_PutEmailIdentityMailFromAttributes_606748, base: "/",
    url: url_PutEmailIdentityMailFromAttributes_606749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEmail_606763 = ref object of OpenApiRestCall_605589
proc url_SendEmail_606765(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_SendEmail_606764(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606766 = header.getOrDefault("X-Amz-Signature")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Signature", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Content-Sha256", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Date")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Date", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Credential")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Credential", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Security-Token")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Security-Token", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-Algorithm")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Algorithm", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-SignedHeaders", valid_606772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606774: Call_SendEmail_606763; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  let valid = call_606774.validator(path, query, header, formData, body)
  let scheme = call_606774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606774.url(scheme.get, call_606774.host, call_606774.base,
                         call_606774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606774, url, valid)

proc call*(call_606775: Call_SendEmail_606763; body: JsonNode): Recallable =
  ## sendEmail
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606776 = newJObject()
  if body != nil:
    body_606776 = body
  result = call_606775.call(nil, nil, nil, nil, body_606776)

var sendEmail* = Call_SendEmail_606763(name: "sendEmail", meth: HttpMethod.HttpPost,
                                    host: "email.amazonaws.com",
                                    route: "/v1/email/outbound-emails",
                                    validator: validate_SendEmail_606764,
                                    base: "/", url: url_SendEmail_606765,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606777 = ref object of OpenApiRestCall_605589
proc url_TagResource_606779(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606778(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606780 = header.getOrDefault("X-Amz-Signature")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Signature", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Content-Sha256", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Date")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Date", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Credential")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Credential", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Security-Token")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Security-Token", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Algorithm")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Algorithm", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-SignedHeaders", valid_606786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606788: Call_TagResource_606777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  let valid = call_606788.validator(path, query, header, formData, body)
  let scheme = call_606788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606788.url(scheme.get, call_606788.host, call_606788.base,
                         call_606788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606788, url, valid)

proc call*(call_606789: Call_TagResource_606777; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   body: JObject (required)
  var body_606790 = newJObject()
  if body != nil:
    body_606790 = body
  result = call_606789.call(nil, nil, nil, nil, body_606790)

var tagResource* = Call_TagResource_606777(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "email.amazonaws.com",
                                        route: "/v1/email/tags",
                                        validator: validate_TagResource_606778,
                                        base: "/", url: url_TagResource_606779,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606791 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606793(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606792(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606794 = query.getOrDefault("TagKeys")
  valid_606794 = validateParameter(valid_606794, JArray, required = true, default = nil)
  if valid_606794 != nil:
    section.add "TagKeys", valid_606794
  var valid_606795 = query.getOrDefault("ResourceArn")
  valid_606795 = validateParameter(valid_606795, JString, required = true,
                                 default = nil)
  if valid_606795 != nil:
    section.add "ResourceArn", valid_606795
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
  var valid_606796 = header.getOrDefault("X-Amz-Signature")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Signature", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Content-Sha256", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Date")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Date", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Credential")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Credential", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Security-Token")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Security-Token", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Algorithm")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Algorithm", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-SignedHeaders", valid_606802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606803: Call_UntagResource_606791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  let valid = call_606803.validator(path, query, header, formData, body)
  let scheme = call_606803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606803.url(scheme.get, call_606803.host, call_606803.base,
                         call_606803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606803, url, valid)

proc call*(call_606804: Call_UntagResource_606791; TagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified resource.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  var query_606805 = newJObject()
  if TagKeys != nil:
    query_606805.add "TagKeys", TagKeys
  add(query_606805, "ResourceArn", newJString(ResourceArn))
  result = call_606804.call(nil, query_606805, nil, nil, nil)

var untagResource* = Call_UntagResource_606791(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "email.amazonaws.com",
    route: "/v1/email/tags#ResourceArn&TagKeys",
    validator: validate_UntagResource_606792, base: "/", url: url_UntagResource_606793,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
