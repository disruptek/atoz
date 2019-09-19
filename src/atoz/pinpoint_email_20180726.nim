
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Pinpoint Email Service
## version: 2018-07-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Pinpoint Email Service</fullname> <p>This document contains reference information for the <a href="https://aws.amazon.com/pinpoint">Amazon Pinpoint</a> Email API, version 1.0. This document is best used in conjunction with the <a href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.</p> <p>The Amazon Pinpoint Email API is available in several AWS Regions and it provides an endpoint for each of these Regions. For a list of all the Regions and endpoints where the API is currently available, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#pinpoint_region">AWS Regions and Endpoints</a> in the <i>Amazon Web Services General Reference</i>.</p> <p>In each Region, AWS maintains multiple Availability Zones. These Availability Zones are physically isolated from each other, but are united by private, low-latency, high-throughput, and highly redundant network connections. These Availability Zones enable us to provide very high levels of availability and redundancy, while also minimizing latency. To learn more about the number of Availability Zones that are available in each Region, see <a href="http://aws.amazon.com/about-aws/global-infrastructure/">AWS Global Infrastructure</a>.</p>
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
              path: JsonNode): string

  OpenApiRestCall_772581 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772581](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772581): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateConfigurationSet_773174 = ref object of OpenApiRestCall_772581
proc url_CreateConfigurationSet_773176(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateConfigurationSet_773175(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773177 = header.getOrDefault("X-Amz-Date")
  valid_773177 = validateParameter(valid_773177, JString, required = false,
                                 default = nil)
  if valid_773177 != nil:
    section.add "X-Amz-Date", valid_773177
  var valid_773178 = header.getOrDefault("X-Amz-Security-Token")
  valid_773178 = validateParameter(valid_773178, JString, required = false,
                                 default = nil)
  if valid_773178 != nil:
    section.add "X-Amz-Security-Token", valid_773178
  var valid_773179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773179 = validateParameter(valid_773179, JString, required = false,
                                 default = nil)
  if valid_773179 != nil:
    section.add "X-Amz-Content-Sha256", valid_773179
  var valid_773180 = header.getOrDefault("X-Amz-Algorithm")
  valid_773180 = validateParameter(valid_773180, JString, required = false,
                                 default = nil)
  if valid_773180 != nil:
    section.add "X-Amz-Algorithm", valid_773180
  var valid_773181 = header.getOrDefault("X-Amz-Signature")
  valid_773181 = validateParameter(valid_773181, JString, required = false,
                                 default = nil)
  if valid_773181 != nil:
    section.add "X-Amz-Signature", valid_773181
  var valid_773182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773182 = validateParameter(valid_773182, JString, required = false,
                                 default = nil)
  if valid_773182 != nil:
    section.add "X-Amz-SignedHeaders", valid_773182
  var valid_773183 = header.getOrDefault("X-Amz-Credential")
  valid_773183 = validateParameter(valid_773183, JString, required = false,
                                 default = nil)
  if valid_773183 != nil:
    section.add "X-Amz-Credential", valid_773183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773185: Call_CreateConfigurationSet_773174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  let valid = call_773185.validator(path, query, header, formData, body)
  let scheme = call_773185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773185.url(scheme.get, call_773185.host, call_773185.base,
                         call_773185.route, valid.getOrDefault("path"))
  result = hook(call_773185, url, valid)

proc call*(call_773186: Call_CreateConfigurationSet_773174; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ##   body: JObject (required)
  var body_773187 = newJObject()
  if body != nil:
    body_773187 = body
  result = call_773186.call(nil, nil, nil, nil, body_773187)

var createConfigurationSet* = Call_CreateConfigurationSet_773174(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_CreateConfigurationSet_773175, base: "/",
    url: url_CreateConfigurationSet_773176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_772917 = ref object of OpenApiRestCall_772581
proc url_ListConfigurationSets_772919(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListConfigurationSets_772918(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  section = newJObject()
  var valid_773031 = query.getOrDefault("PageSize")
  valid_773031 = validateParameter(valid_773031, JInt, required = false, default = nil)
  if valid_773031 != nil:
    section.add "PageSize", valid_773031
  var valid_773032 = query.getOrDefault("NextToken")
  valid_773032 = validateParameter(valid_773032, JString, required = false,
                                 default = nil)
  if valid_773032 != nil:
    section.add "NextToken", valid_773032
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
  var valid_773033 = header.getOrDefault("X-Amz-Date")
  valid_773033 = validateParameter(valid_773033, JString, required = false,
                                 default = nil)
  if valid_773033 != nil:
    section.add "X-Amz-Date", valid_773033
  var valid_773034 = header.getOrDefault("X-Amz-Security-Token")
  valid_773034 = validateParameter(valid_773034, JString, required = false,
                                 default = nil)
  if valid_773034 != nil:
    section.add "X-Amz-Security-Token", valid_773034
  var valid_773035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773035 = validateParameter(valid_773035, JString, required = false,
                                 default = nil)
  if valid_773035 != nil:
    section.add "X-Amz-Content-Sha256", valid_773035
  var valid_773036 = header.getOrDefault("X-Amz-Algorithm")
  valid_773036 = validateParameter(valid_773036, JString, required = false,
                                 default = nil)
  if valid_773036 != nil:
    section.add "X-Amz-Algorithm", valid_773036
  var valid_773037 = header.getOrDefault("X-Amz-Signature")
  valid_773037 = validateParameter(valid_773037, JString, required = false,
                                 default = nil)
  if valid_773037 != nil:
    section.add "X-Amz-Signature", valid_773037
  var valid_773038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773038 = validateParameter(valid_773038, JString, required = false,
                                 default = nil)
  if valid_773038 != nil:
    section.add "X-Amz-SignedHeaders", valid_773038
  var valid_773039 = header.getOrDefault("X-Amz-Credential")
  valid_773039 = validateParameter(valid_773039, JString, required = false,
                                 default = nil)
  if valid_773039 != nil:
    section.add "X-Amz-Credential", valid_773039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773062: Call_ListConfigurationSets_772917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_773062.validator(path, query, header, formData, body)
  let scheme = call_773062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773062.url(scheme.get, call_773062.host, call_773062.base,
                         call_773062.route, valid.getOrDefault("path"))
  result = hook(call_773062, url, valid)

proc call*(call_773133: Call_ListConfigurationSets_772917; PageSize: int = 0;
          NextToken: string = ""): Recallable =
  ## listConfigurationSets
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  var query_773134 = newJObject()
  add(query_773134, "PageSize", newJInt(PageSize))
  add(query_773134, "NextToken", newJString(NextToken))
  result = call_773133.call(nil, query_773134, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_772917(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_ListConfigurationSets_772918, base: "/",
    url: url_ListConfigurationSets_772919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_773216 = ref object of OpenApiRestCall_772581
proc url_CreateConfigurationSetEventDestination_773218(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateConfigurationSetEventDestination_773217(path: JsonNode;
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
  var valid_773219 = path.getOrDefault("ConfigurationSetName")
  valid_773219 = validateParameter(valid_773219, JString, required = true,
                                 default = nil)
  if valid_773219 != nil:
    section.add "ConfigurationSetName", valid_773219
  result.add "path", section
  section = newJObject()
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Content-Sha256", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Algorithm")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Algorithm", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Signature")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Signature", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-SignedHeaders", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Credential")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Credential", valid_773226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773228: Call_CreateConfigurationSetEventDestination_773216;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  let valid = call_773228.validator(path, query, header, formData, body)
  let scheme = call_773228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773228.url(scheme.get, call_773228.host, call_773228.base,
                         call_773228.route, valid.getOrDefault("path"))
  result = hook(call_773228, url, valid)

proc call*(call_773229: Call_CreateConfigurationSetEventDestination_773216;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_773230 = newJObject()
  var body_773231 = newJObject()
  add(path_773230, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_773231 = body
  result = call_773229.call(path_773230, nil, nil, nil, body_773231)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_773216(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_773217, base: "/",
    url: url_CreateConfigurationSetEventDestination_773218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_773188 = ref object of OpenApiRestCall_772581
proc url_GetConfigurationSetEventDestinations_773190(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetConfigurationSetEventDestinations_773189(path: JsonNode;
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
  var valid_773205 = path.getOrDefault("ConfigurationSetName")
  valid_773205 = validateParameter(valid_773205, JString, required = true,
                                 default = nil)
  if valid_773205 != nil:
    section.add "ConfigurationSetName", valid_773205
  result.add "path", section
  section = newJObject()
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
  var valid_773206 = header.getOrDefault("X-Amz-Date")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Date", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Security-Token")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Security-Token", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773213: Call_GetConfigurationSetEventDestinations_773188;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_773213.validator(path, query, header, formData, body)
  let scheme = call_773213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773213.url(scheme.get, call_773213.host, call_773213.base,
                         call_773213.route, valid.getOrDefault("path"))
  result = hook(call_773213, url, valid)

proc call*(call_773214: Call_GetConfigurationSetEventDestinations_773188;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_773215 = newJObject()
  add(path_773215, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_773214.call(path_773215, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_773188(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_773189, base: "/",
    url: url_GetConfigurationSetEventDestinations_773190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDedicatedIpPool_773247 = ref object of OpenApiRestCall_772581
proc url_CreateDedicatedIpPool_773249(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDedicatedIpPool_773248(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Content-Sha256", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Algorithm")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Algorithm", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Signature")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Signature", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-SignedHeaders", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Credential")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Credential", valid_773256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773258: Call_CreateDedicatedIpPool_773247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ## 
  let valid = call_773258.validator(path, query, header, formData, body)
  let scheme = call_773258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773258.url(scheme.get, call_773258.host, call_773258.base,
                         call_773258.route, valid.getOrDefault("path"))
  result = hook(call_773258, url, valid)

proc call*(call_773259: Call_CreateDedicatedIpPool_773247; body: JsonNode): Recallable =
  ## createDedicatedIpPool
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ##   body: JObject (required)
  var body_773260 = newJObject()
  if body != nil:
    body_773260 = body
  result = call_773259.call(nil, nil, nil, nil, body_773260)

var createDedicatedIpPool* = Call_CreateDedicatedIpPool_773247(
    name: "createDedicatedIpPool", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_CreateDedicatedIpPool_773248, base: "/",
    url: url_CreateDedicatedIpPool_773249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDedicatedIpPools_773232 = ref object of OpenApiRestCall_772581
proc url_ListDedicatedIpPools_773234(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDedicatedIpPools_773233(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  section = newJObject()
  var valid_773235 = query.getOrDefault("PageSize")
  valid_773235 = validateParameter(valid_773235, JInt, required = false, default = nil)
  if valid_773235 != nil:
    section.add "PageSize", valid_773235
  var valid_773236 = query.getOrDefault("NextToken")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "NextToken", valid_773236
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
  var valid_773237 = header.getOrDefault("X-Amz-Date")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Date", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Security-Token")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Security-Token", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Content-Sha256", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Algorithm")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Algorithm", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Signature")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Signature", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-SignedHeaders", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Credential")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Credential", valid_773243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_ListDedicatedIpPools_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_ListDedicatedIpPools_773232; PageSize: int = 0;
          NextToken: string = ""): Recallable =
  ## listDedicatedIpPools
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  var query_773246 = newJObject()
  add(query_773246, "PageSize", newJInt(PageSize))
  add(query_773246, "NextToken", newJString(NextToken))
  result = call_773245.call(nil, query_773246, nil, nil, nil)

var listDedicatedIpPools* = Call_ListDedicatedIpPools_773232(
    name: "listDedicatedIpPools", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_ListDedicatedIpPools_773233, base: "/",
    url: url_ListDedicatedIpPools_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeliverabilityTestReport_773261 = ref object of OpenApiRestCall_772581
proc url_CreateDeliverabilityTestReport_773263(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDeliverabilityTestReport_773262(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773264 = header.getOrDefault("X-Amz-Date")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Date", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Security-Token")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Security-Token", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Content-Sha256", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Algorithm")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Algorithm", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Signature")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Signature", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-SignedHeaders", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Credential")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Credential", valid_773270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773272: Call_CreateDeliverabilityTestReport_773261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  let valid = call_773272.validator(path, query, header, formData, body)
  let scheme = call_773272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773272.url(scheme.get, call_773272.host, call_773272.base,
                         call_773272.route, valid.getOrDefault("path"))
  result = hook(call_773272, url, valid)

proc call*(call_773273: Call_CreateDeliverabilityTestReport_773261; body: JsonNode): Recallable =
  ## createDeliverabilityTestReport
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ##   body: JObject (required)
  var body_773274 = newJObject()
  if body != nil:
    body_773274 = body
  result = call_773273.call(nil, nil, nil, nil, body_773274)

var createDeliverabilityTestReport* = Call_CreateDeliverabilityTestReport_773261(
    name: "createDeliverabilityTestReport", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/test",
    validator: validate_CreateDeliverabilityTestReport_773262, base: "/",
    url: url_CreateDeliverabilityTestReport_773263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailIdentity_773290 = ref object of OpenApiRestCall_772581
proc url_CreateEmailIdentity_773292(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEmailIdentity_773291(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773293 = header.getOrDefault("X-Amz-Date")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Date", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Security-Token")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Security-Token", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Content-Sha256", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Algorithm")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Algorithm", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Signature")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Signature", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-SignedHeaders", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Credential")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Credential", valid_773299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773301: Call_CreateEmailIdentity_773290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ## 
  let valid = call_773301.validator(path, query, header, formData, body)
  let scheme = call_773301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773301.url(scheme.get, call_773301.host, call_773301.base,
                         call_773301.route, valid.getOrDefault("path"))
  result = hook(call_773301, url, valid)

proc call*(call_773302: Call_CreateEmailIdentity_773290; body: JsonNode): Recallable =
  ## createEmailIdentity
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ##   body: JObject (required)
  var body_773303 = newJObject()
  if body != nil:
    body_773303 = body
  result = call_773302.call(nil, nil, nil, nil, body_773303)

var createEmailIdentity* = Call_CreateEmailIdentity_773290(
    name: "createEmailIdentity", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_CreateEmailIdentity_773291, base: "/",
    url: url_CreateEmailIdentity_773292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEmailIdentities_773275 = ref object of OpenApiRestCall_772581
proc url_ListEmailIdentities_773277(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEmailIdentities_773276(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  section = newJObject()
  var valid_773278 = query.getOrDefault("PageSize")
  valid_773278 = validateParameter(valid_773278, JInt, required = false, default = nil)
  if valid_773278 != nil:
    section.add "PageSize", valid_773278
  var valid_773279 = query.getOrDefault("NextToken")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "NextToken", valid_773279
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Content-Sha256", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Algorithm")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Algorithm", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Signature")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Signature", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-SignedHeaders", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Credential")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Credential", valid_773286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773287: Call_ListEmailIdentities_773275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ## 
  let valid = call_773287.validator(path, query, header, formData, body)
  let scheme = call_773287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773287.url(scheme.get, call_773287.host, call_773287.base,
                         call_773287.route, valid.getOrDefault("path"))
  result = hook(call_773287, url, valid)

proc call*(call_773288: Call_ListEmailIdentities_773275; PageSize: int = 0;
          NextToken: string = ""): Recallable =
  ## listEmailIdentities
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  var query_773289 = newJObject()
  add(query_773289, "PageSize", newJInt(PageSize))
  add(query_773289, "NextToken", newJString(NextToken))
  result = call_773288.call(nil, query_773289, nil, nil, nil)

var listEmailIdentities* = Call_ListEmailIdentities_773275(
    name: "listEmailIdentities", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_ListEmailIdentities_773276, base: "/",
    url: url_ListEmailIdentities_773277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSet_773304 = ref object of OpenApiRestCall_772581
proc url_GetConfigurationSet_773306(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetConfigurationSet_773305(path: JsonNode; query: JsonNode;
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
  var valid_773307 = path.getOrDefault("ConfigurationSetName")
  valid_773307 = validateParameter(valid_773307, JString, required = true,
                                 default = nil)
  if valid_773307 != nil:
    section.add "ConfigurationSetName", valid_773307
  result.add "path", section
  section = newJObject()
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
  var valid_773308 = header.getOrDefault("X-Amz-Date")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Date", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Security-Token")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Security-Token", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Content-Sha256", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Algorithm")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Algorithm", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Signature")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Signature", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-SignedHeaders", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Credential")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Credential", valid_773314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773315: Call_GetConfigurationSet_773304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_773315.validator(path, query, header, formData, body)
  let scheme = call_773315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773315.url(scheme.get, call_773315.host, call_773315.base,
                         call_773315.route, valid.getOrDefault("path"))
  result = hook(call_773315, url, valid)

proc call*(call_773316: Call_GetConfigurationSet_773304;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSet
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_773317 = newJObject()
  add(path_773317, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_773316.call(path_773317, nil, nil, nil, nil)

var getConfigurationSet* = Call_GetConfigurationSet_773304(
    name: "getConfigurationSet", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_GetConfigurationSet_773305, base: "/",
    url: url_GetConfigurationSet_773306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_773318 = ref object of OpenApiRestCall_772581
proc url_DeleteConfigurationSet_773320(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteConfigurationSet_773319(path: JsonNode; query: JsonNode;
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
  var valid_773321 = path.getOrDefault("ConfigurationSetName")
  valid_773321 = validateParameter(valid_773321, JString, required = true,
                                 default = nil)
  if valid_773321 != nil:
    section.add "ConfigurationSetName", valid_773321
  result.add "path", section
  section = newJObject()
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
  var valid_773322 = header.getOrDefault("X-Amz-Date")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Date", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Security-Token")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Security-Token", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Content-Sha256", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Algorithm")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Algorithm", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Signature")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Signature", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-SignedHeaders", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Credential")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Credential", valid_773328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773329: Call_DeleteConfigurationSet_773318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_773329.validator(path, query, header, formData, body)
  let scheme = call_773329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773329.url(scheme.get, call_773329.host, call_773329.base,
                         call_773329.route, valid.getOrDefault("path"))
  result = hook(call_773329, url, valid)

proc call*(call_773330: Call_DeleteConfigurationSet_773318;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_773331 = newJObject()
  add(path_773331, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_773330.call(path_773331, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_773318(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_773319, base: "/",
    url: url_DeleteConfigurationSet_773320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_773332 = ref object of OpenApiRestCall_772581
proc url_UpdateConfigurationSetEventDestination_773334(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateConfigurationSetEventDestination_773333(path: JsonNode;
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
  var valid_773335 = path.getOrDefault("ConfigurationSetName")
  valid_773335 = validateParameter(valid_773335, JString, required = true,
                                 default = nil)
  if valid_773335 != nil:
    section.add "ConfigurationSetName", valid_773335
  var valid_773336 = path.getOrDefault("EventDestinationName")
  valid_773336 = validateParameter(valid_773336, JString, required = true,
                                 default = nil)
  if valid_773336 != nil:
    section.add "EventDestinationName", valid_773336
  result.add "path", section
  section = newJObject()
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
  var valid_773337 = header.getOrDefault("X-Amz-Date")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Date", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-Security-Token")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Security-Token", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Content-Sha256", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-Algorithm")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Algorithm", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Signature")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Signature", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-SignedHeaders", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Credential")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Credential", valid_773343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773345: Call_UpdateConfigurationSetEventDestination_773332;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_773345.validator(path, query, header, formData, body)
  let scheme = call_773345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773345.url(scheme.get, call_773345.host, call_773345.base,
                         call_773345.route, valid.getOrDefault("path"))
  result = hook(call_773345, url, valid)

proc call*(call_773346: Call_UpdateConfigurationSetEventDestination_773332;
          ConfigurationSetName: string; body: JsonNode; EventDestinationName: string): Recallable =
  ## updateConfigurationSetEventDestination
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_773347 = newJObject()
  var body_773348 = newJObject()
  add(path_773347, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_773348 = body
  add(path_773347, "EventDestinationName", newJString(EventDestinationName))
  result = call_773346.call(path_773347, nil, nil, nil, body_773348)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_773332(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_773333, base: "/",
    url: url_UpdateConfigurationSetEventDestination_773334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_773349 = ref object of OpenApiRestCall_772581
proc url_DeleteConfigurationSetEventDestination_773351(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteConfigurationSetEventDestination_773350(path: JsonNode;
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
  var valid_773352 = path.getOrDefault("ConfigurationSetName")
  valid_773352 = validateParameter(valid_773352, JString, required = true,
                                 default = nil)
  if valid_773352 != nil:
    section.add "ConfigurationSetName", valid_773352
  var valid_773353 = path.getOrDefault("EventDestinationName")
  valid_773353 = validateParameter(valid_773353, JString, required = true,
                                 default = nil)
  if valid_773353 != nil:
    section.add "EventDestinationName", valid_773353
  result.add "path", section
  section = newJObject()
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
  var valid_773354 = header.getOrDefault("X-Amz-Date")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Date", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Security-Token")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Security-Token", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Content-Sha256", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Algorithm")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Algorithm", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Signature")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Signature", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-SignedHeaders", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Credential")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Credential", valid_773360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773361: Call_DeleteConfigurationSetEventDestination_773349;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_773361.validator(path, query, header, formData, body)
  let scheme = call_773361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773361.url(scheme.get, call_773361.host, call_773361.base,
                         call_773361.route, valid.getOrDefault("path"))
  result = hook(call_773361, url, valid)

proc call*(call_773362: Call_DeleteConfigurationSetEventDestination_773349;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_773363 = newJObject()
  add(path_773363, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_773363, "EventDestinationName", newJString(EventDestinationName))
  result = call_773362.call(path_773363, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_773349(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_773350, base: "/",
    url: url_DeleteConfigurationSetEventDestination_773351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDedicatedIpPool_773364 = ref object of OpenApiRestCall_772581
proc url_DeleteDedicatedIpPool_773366(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "PoolName" in path, "`PoolName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ip-pools/"),
               (kind: VariableSegment, value: "PoolName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDedicatedIpPool_773365(path: JsonNode; query: JsonNode;
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
  var valid_773367 = path.getOrDefault("PoolName")
  valid_773367 = validateParameter(valid_773367, JString, required = true,
                                 default = nil)
  if valid_773367 != nil:
    section.add "PoolName", valid_773367
  result.add "path", section
  section = newJObject()
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
  var valid_773368 = header.getOrDefault("X-Amz-Date")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Date", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Security-Token")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Security-Token", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Content-Sha256", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Algorithm")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Algorithm", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Signature")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Signature", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-SignedHeaders", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Credential")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Credential", valid_773374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773375: Call_DeleteDedicatedIpPool_773364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a dedicated IP pool.
  ## 
  let valid = call_773375.validator(path, query, header, formData, body)
  let scheme = call_773375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773375.url(scheme.get, call_773375.host, call_773375.base,
                         call_773375.route, valid.getOrDefault("path"))
  result = hook(call_773375, url, valid)

proc call*(call_773376: Call_DeleteDedicatedIpPool_773364; PoolName: string): Recallable =
  ## deleteDedicatedIpPool
  ## Delete a dedicated IP pool.
  ##   PoolName: string (required)
  ##           : The name of a dedicated IP pool.
  var path_773377 = newJObject()
  add(path_773377, "PoolName", newJString(PoolName))
  result = call_773376.call(path_773377, nil, nil, nil, nil)

var deleteDedicatedIpPool* = Call_DeleteDedicatedIpPool_773364(
    name: "deleteDedicatedIpPool", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools/{PoolName}",
    validator: validate_DeleteDedicatedIpPool_773365, base: "/",
    url: url_DeleteDedicatedIpPool_773366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailIdentity_773378 = ref object of OpenApiRestCall_772581
proc url_GetEmailIdentity_773380(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetEmailIdentity_773379(path: JsonNode; query: JsonNode;
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
  var valid_773381 = path.getOrDefault("EmailIdentity")
  valid_773381 = validateParameter(valid_773381, JString, required = true,
                                 default = nil)
  if valid_773381 != nil:
    section.add "EmailIdentity", valid_773381
  result.add "path", section
  section = newJObject()
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
  var valid_773382 = header.getOrDefault("X-Amz-Date")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-Date", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Security-Token")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Security-Token", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Content-Sha256", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Algorithm")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Algorithm", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Signature")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Signature", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-SignedHeaders", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Credential")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Credential", valid_773388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773389: Call_GetEmailIdentity_773378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  let valid = call_773389.validator(path, query, header, formData, body)
  let scheme = call_773389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773389.url(scheme.get, call_773389.host, call_773389.base,
                         call_773389.route, valid.getOrDefault("path"))
  result = hook(call_773389, url, valid)

proc call*(call_773390: Call_GetEmailIdentity_773378; EmailIdentity: string): Recallable =
  ## getEmailIdentity
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to retrieve details for.
  var path_773391 = newJObject()
  add(path_773391, "EmailIdentity", newJString(EmailIdentity))
  result = call_773390.call(path_773391, nil, nil, nil, nil)

var getEmailIdentity* = Call_GetEmailIdentity_773378(name: "getEmailIdentity",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_GetEmailIdentity_773379, base: "/",
    url: url_GetEmailIdentity_773380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailIdentity_773392 = ref object of OpenApiRestCall_772581
proc url_DeleteEmailIdentity_773394(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteEmailIdentity_773393(path: JsonNode; query: JsonNode;
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
  var valid_773395 = path.getOrDefault("EmailIdentity")
  valid_773395 = validateParameter(valid_773395, JString, required = true,
                                 default = nil)
  if valid_773395 != nil:
    section.add "EmailIdentity", valid_773395
  result.add "path", section
  section = newJObject()
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
  var valid_773396 = header.getOrDefault("X-Amz-Date")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Date", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Security-Token")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Security-Token", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Content-Sha256", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Algorithm")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Algorithm", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-Signature")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Signature", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-SignedHeaders", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Credential")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Credential", valid_773402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773403: Call_DeleteEmailIdentity_773392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ## 
  let valid = call_773403.validator(path, query, header, formData, body)
  let scheme = call_773403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773403.url(scheme.get, call_773403.host, call_773403.base,
                         call_773403.route, valid.getOrDefault("path"))
  result = hook(call_773403, url, valid)

proc call*(call_773404: Call_DeleteEmailIdentity_773392; EmailIdentity: string): Recallable =
  ## deleteEmailIdentity
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ##   EmailIdentity: string (required)
  ##                : The identity (that is, the email address or domain) that you want to delete from your Amazon Pinpoint account.
  var path_773405 = newJObject()
  add(path_773405, "EmailIdentity", newJString(EmailIdentity))
  result = call_773404.call(path_773405, nil, nil, nil, nil)

var deleteEmailIdentity* = Call_DeleteEmailIdentity_773392(
    name: "deleteEmailIdentity", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_DeleteEmailIdentity_773393, base: "/",
    url: url_DeleteEmailIdentity_773394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_773406 = ref object of OpenApiRestCall_772581
proc url_GetAccount_773408(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAccount_773407(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773409 = header.getOrDefault("X-Amz-Date")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Date", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Security-Token")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Security-Token", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Content-Sha256", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Algorithm")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Algorithm", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Signature")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Signature", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-SignedHeaders", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Credential")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Credential", valid_773415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773416: Call_GetAccount_773406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_773416.validator(path, query, header, formData, body)
  let scheme = call_773416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773416.url(scheme.get, call_773416.host, call_773416.base,
                         call_773416.route, valid.getOrDefault("path"))
  result = hook(call_773416, url, valid)

proc call*(call_773417: Call_GetAccount_773406): Recallable =
  ## getAccount
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  result = call_773417.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_773406(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "email.amazonaws.com",
                                      route: "/v1/email/account",
                                      validator: validate_GetAccount_773407,
                                      base: "/", url: url_GetAccount_773408,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlacklistReports_773418 = ref object of OpenApiRestCall_772581
proc url_GetBlacklistReports_773420(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetBlacklistReports_773419(path: JsonNode; query: JsonNode;
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
  var valid_773421 = query.getOrDefault("BlacklistItemNames")
  valid_773421 = validateParameter(valid_773421, JArray, required = true, default = nil)
  if valid_773421 != nil:
    section.add "BlacklistItemNames", valid_773421
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
  var valid_773422 = header.getOrDefault("X-Amz-Date")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Date", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Security-Token")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Security-Token", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Content-Sha256", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Algorithm")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Algorithm", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Signature")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Signature", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-SignedHeaders", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Credential")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Credential", valid_773428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773429: Call_GetBlacklistReports_773418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ## 
  let valid = call_773429.validator(path, query, header, formData, body)
  let scheme = call_773429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773429.url(scheme.get, call_773429.host, call_773429.base,
                         call_773429.route, valid.getOrDefault("path"))
  result = hook(call_773429, url, valid)

proc call*(call_773430: Call_GetBlacklistReports_773418;
          BlacklistItemNames: JsonNode): Recallable =
  ## getBlacklistReports
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ##   BlacklistItemNames: JArray (required)
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon Pinpoint or Amazon SES.
  var query_773431 = newJObject()
  if BlacklistItemNames != nil:
    query_773431.add "BlacklistItemNames", BlacklistItemNames
  result = call_773430.call(nil, query_773431, nil, nil, nil)

var getBlacklistReports* = Call_GetBlacklistReports_773418(
    name: "getBlacklistReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/blacklist-report#BlacklistItemNames",
    validator: validate_GetBlacklistReports_773419, base: "/",
    url: url_GetBlacklistReports_773420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIp_773432 = ref object of OpenApiRestCall_772581
proc url_GetDedicatedIp_773434(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDedicatedIp_773433(path: JsonNode; query: JsonNode;
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
  var valid_773435 = path.getOrDefault("IP")
  valid_773435 = validateParameter(valid_773435, JString, required = true,
                                 default = nil)
  if valid_773435 != nil:
    section.add "IP", valid_773435
  result.add "path", section
  section = newJObject()
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
  var valid_773436 = header.getOrDefault("X-Amz-Date")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Date", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Security-Token")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Security-Token", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Content-Sha256", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Algorithm")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Algorithm", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Signature")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Signature", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-SignedHeaders", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Credential")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Credential", valid_773442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773443: Call_GetDedicatedIp_773432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  let valid = call_773443.validator(path, query, header, formData, body)
  let scheme = call_773443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773443.url(scheme.get, call_773443.host, call_773443.base,
                         call_773443.route, valid.getOrDefault("path"))
  result = hook(call_773443, url, valid)

proc call*(call_773444: Call_GetDedicatedIp_773432; IP: string): Recallable =
  ## getDedicatedIp
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  var path_773445 = newJObject()
  add(path_773445, "IP", newJString(IP))
  result = call_773444.call(path_773445, nil, nil, nil, nil)

var getDedicatedIp* = Call_GetDedicatedIp_773432(name: "getDedicatedIp",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips/{IP}", validator: validate_GetDedicatedIp_773433,
    base: "/", url: url_GetDedicatedIp_773434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIps_773446 = ref object of OpenApiRestCall_772581
proc url_GetDedicatedIps_773448(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDedicatedIps_773447(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PoolName: JString
  ##           : The name of a dedicated IP pool.
  section = newJObject()
  var valid_773449 = query.getOrDefault("PageSize")
  valid_773449 = validateParameter(valid_773449, JInt, required = false, default = nil)
  if valid_773449 != nil:
    section.add "PageSize", valid_773449
  var valid_773450 = query.getOrDefault("NextToken")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "NextToken", valid_773450
  var valid_773451 = query.getOrDefault("PoolName")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "PoolName", valid_773451
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
  var valid_773452 = header.getOrDefault("X-Amz-Date")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Date", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Security-Token")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Security-Token", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Content-Sha256", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Algorithm")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Algorithm", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Signature")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Signature", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-SignedHeaders", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Credential")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Credential", valid_773458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773459: Call_GetDedicatedIps_773446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_773459.validator(path, query, header, formData, body)
  let scheme = call_773459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773459.url(scheme.get, call_773459.host, call_773459.base,
                         call_773459.route, valid.getOrDefault("path"))
  result = hook(call_773459, url, valid)

proc call*(call_773460: Call_GetDedicatedIps_773446; PageSize: int = 0;
          NextToken: string = ""; PoolName: string = ""): Recallable =
  ## getDedicatedIps
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PoolName: string
  ##           : The name of a dedicated IP pool.
  var query_773461 = newJObject()
  add(query_773461, "PageSize", newJInt(PageSize))
  add(query_773461, "NextToken", newJString(NextToken))
  add(query_773461, "PoolName", newJString(PoolName))
  result = call_773460.call(nil, query_773461, nil, nil, nil)

var getDedicatedIps* = Call_GetDedicatedIps_773446(name: "getDedicatedIps",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips", validator: validate_GetDedicatedIps_773447,
    base: "/", url: url_GetDedicatedIps_773448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliverabilityDashboardOption_773474 = ref object of OpenApiRestCall_772581
proc url_PutDeliverabilityDashboardOption_773476(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutDeliverabilityDashboardOption_773475(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773477 = header.getOrDefault("X-Amz-Date")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-Date", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Security-Token")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Security-Token", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Content-Sha256", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Algorithm")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Algorithm", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Signature")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Signature", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-SignedHeaders", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Credential")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Credential", valid_773483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773485: Call_PutDeliverabilityDashboardOption_773474;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_773485.validator(path, query, header, formData, body)
  let scheme = call_773485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773485.url(scheme.get, call_773485.host, call_773485.base,
                         call_773485.route, valid.getOrDefault("path"))
  result = hook(call_773485, url, valid)

proc call*(call_773486: Call_PutDeliverabilityDashboardOption_773474;
          body: JsonNode): Recallable =
  ## putDeliverabilityDashboardOption
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ##   body: JObject (required)
  var body_773487 = newJObject()
  if body != nil:
    body_773487 = body
  result = call_773486.call(nil, nil, nil, nil, body_773487)

var putDeliverabilityDashboardOption* = Call_PutDeliverabilityDashboardOption_773474(
    name: "putDeliverabilityDashboardOption", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_PutDeliverabilityDashboardOption_773475, base: "/",
    url: url_PutDeliverabilityDashboardOption_773476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityDashboardOptions_773462 = ref object of OpenApiRestCall_772581
proc url_GetDeliverabilityDashboardOptions_773464(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeliverabilityDashboardOptions_773463(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773465 = header.getOrDefault("X-Amz-Date")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Date", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Security-Token")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Security-Token", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Content-Sha256", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Algorithm")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Algorithm", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Signature")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Signature", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-SignedHeaders", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Credential")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Credential", valid_773471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773472: Call_GetDeliverabilityDashboardOptions_773462;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_773472.validator(path, query, header, formData, body)
  let scheme = call_773472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773472.url(scheme.get, call_773472.host, call_773472.base,
                         call_773472.route, valid.getOrDefault("path"))
  result = hook(call_773472, url, valid)

proc call*(call_773473: Call_GetDeliverabilityDashboardOptions_773462): Recallable =
  ## getDeliverabilityDashboardOptions
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  result = call_773473.call(nil, nil, nil, nil, nil)

var getDeliverabilityDashboardOptions* = Call_GetDeliverabilityDashboardOptions_773462(
    name: "getDeliverabilityDashboardOptions", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_GetDeliverabilityDashboardOptions_773463, base: "/",
    url: url_GetDeliverabilityDashboardOptions_773464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityTestReport_773488 = ref object of OpenApiRestCall_772581
proc url_GetDeliverabilityTestReport_773490(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ReportId" in path, "`ReportId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/test-reports/"),
               (kind: VariableSegment, value: "ReportId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDeliverabilityTestReport_773489(path: JsonNode; query: JsonNode;
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
  var valid_773491 = path.getOrDefault("ReportId")
  valid_773491 = validateParameter(valid_773491, JString, required = true,
                                 default = nil)
  if valid_773491 != nil:
    section.add "ReportId", valid_773491
  result.add "path", section
  section = newJObject()
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
  var valid_773492 = header.getOrDefault("X-Amz-Date")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-Date", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Security-Token")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Security-Token", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Content-Sha256", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Algorithm")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Algorithm", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-Signature")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Signature", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-SignedHeaders", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-Credential")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Credential", valid_773498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773499: Call_GetDeliverabilityTestReport_773488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  let valid = call_773499.validator(path, query, header, formData, body)
  let scheme = call_773499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773499.url(scheme.get, call_773499.host, call_773499.base,
                         call_773499.route, valid.getOrDefault("path"))
  result = hook(call_773499, url, valid)

proc call*(call_773500: Call_GetDeliverabilityTestReport_773488; ReportId: string): Recallable =
  ## getDeliverabilityTestReport
  ## Retrieve the results of a predictive inbox placement test.
  ##   ReportId: string (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  var path_773501 = newJObject()
  add(path_773501, "ReportId", newJString(ReportId))
  result = call_773500.call(path_773501, nil, nil, nil, nil)

var getDeliverabilityTestReport* = Call_GetDeliverabilityTestReport_773488(
    name: "getDeliverabilityTestReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports/{ReportId}",
    validator: validate_GetDeliverabilityTestReport_773489, base: "/",
    url: url_GetDeliverabilityTestReport_773490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDeliverabilityCampaign_773502 = ref object of OpenApiRestCall_772581
proc url_GetDomainDeliverabilityCampaign_773504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "CampaignId" in path, "`CampaignId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/campaigns/"),
               (kind: VariableSegment, value: "CampaignId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDomainDeliverabilityCampaign_773503(path: JsonNode;
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
  var valid_773505 = path.getOrDefault("CampaignId")
  valid_773505 = validateParameter(valid_773505, JString, required = true,
                                 default = nil)
  if valid_773505 != nil:
    section.add "CampaignId", valid_773505
  result.add "path", section
  section = newJObject()
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
  var valid_773506 = header.getOrDefault("X-Amz-Date")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Date", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Security-Token")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Security-Token", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Content-Sha256", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Algorithm")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Algorithm", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Signature")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Signature", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-SignedHeaders", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Credential")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Credential", valid_773512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773513: Call_GetDomainDeliverabilityCampaign_773502;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ## 
  let valid = call_773513.validator(path, query, header, formData, body)
  let scheme = call_773513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773513.url(scheme.get, call_773513.host, call_773513.base,
                         call_773513.route, valid.getOrDefault("path"))
  result = hook(call_773513, url, valid)

proc call*(call_773514: Call_GetDomainDeliverabilityCampaign_773502;
          CampaignId: string): Recallable =
  ## getDomainDeliverabilityCampaign
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ##   CampaignId: string (required)
  ##             : The unique identifier for the campaign. Amazon Pinpoint automatically generates and assigns this identifier to a campaign. This value is not the same as the campaign identifier that Amazon Pinpoint assigns to campaigns that you create and manage by using the Amazon Pinpoint API or the Amazon Pinpoint console.
  var path_773515 = newJObject()
  add(path_773515, "CampaignId", newJString(CampaignId))
  result = call_773514.call(path_773515, nil, nil, nil, nil)

var getDomainDeliverabilityCampaign* = Call_GetDomainDeliverabilityCampaign_773502(
    name: "getDomainDeliverabilityCampaign", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/campaigns/{CampaignId}",
    validator: validate_GetDomainDeliverabilityCampaign_773503, base: "/",
    url: url_GetDomainDeliverabilityCampaign_773504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainStatisticsReport_773516 = ref object of OpenApiRestCall_772581
proc url_GetDomainStatisticsReport_773518(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDomainStatisticsReport_773517(path: JsonNode; query: JsonNode;
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
  var valid_773519 = path.getOrDefault("Domain")
  valid_773519 = validateParameter(valid_773519, JString, required = true,
                                 default = nil)
  if valid_773519 != nil:
    section.add "Domain", valid_773519
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: JString (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_773520 = query.getOrDefault("EndDate")
  valid_773520 = validateParameter(valid_773520, JString, required = true,
                                 default = nil)
  if valid_773520 != nil:
    section.add "EndDate", valid_773520
  var valid_773521 = query.getOrDefault("StartDate")
  valid_773521 = validateParameter(valid_773521, JString, required = true,
                                 default = nil)
  if valid_773521 != nil:
    section.add "StartDate", valid_773521
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
  var valid_773522 = header.getOrDefault("X-Amz-Date")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Date", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Security-Token")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Security-Token", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Content-Sha256", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Algorithm")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Algorithm", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-Signature")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-Signature", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-SignedHeaders", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Credential")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Credential", valid_773528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773529: Call_GetDomainStatisticsReport_773516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  let valid = call_773529.validator(path, query, header, formData, body)
  let scheme = call_773529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773529.url(scheme.get, call_773529.host, call_773529.base,
                         call_773529.route, valid.getOrDefault("path"))
  result = hook(call_773529, url, valid)

proc call*(call_773530: Call_GetDomainStatisticsReport_773516; Domain: string;
          EndDate: string; StartDate: string): Recallable =
  ## getDomainStatisticsReport
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ##   Domain: string (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  ##   EndDate: string (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: string (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  var path_773531 = newJObject()
  var query_773532 = newJObject()
  add(path_773531, "Domain", newJString(Domain))
  add(query_773532, "EndDate", newJString(EndDate))
  add(query_773532, "StartDate", newJString(StartDate))
  result = call_773530.call(path_773531, query_773532, nil, nil, nil)

var getDomainStatisticsReport* = Call_GetDomainStatisticsReport_773516(
    name: "getDomainStatisticsReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/statistics-report/{Domain}#StartDate&EndDate",
    validator: validate_GetDomainStatisticsReport_773517, base: "/",
    url: url_GetDomainStatisticsReport_773518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeliverabilityTestReports_773533 = ref object of OpenApiRestCall_772581
proc url_ListDeliverabilityTestReports_773535(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeliverabilityTestReports_773534(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  section = newJObject()
  var valid_773536 = query.getOrDefault("PageSize")
  valid_773536 = validateParameter(valid_773536, JInt, required = false, default = nil)
  if valid_773536 != nil:
    section.add "PageSize", valid_773536
  var valid_773537 = query.getOrDefault("NextToken")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "NextToken", valid_773537
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
  var valid_773538 = header.getOrDefault("X-Amz-Date")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Date", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Security-Token")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Security-Token", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Content-Sha256", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-Algorithm")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-Algorithm", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Signature")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Signature", valid_773542
  var valid_773543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-SignedHeaders", valid_773543
  var valid_773544 = header.getOrDefault("X-Amz-Credential")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Credential", valid_773544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773545: Call_ListDeliverabilityTestReports_773533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  let valid = call_773545.validator(path, query, header, formData, body)
  let scheme = call_773545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773545.url(scheme.get, call_773545.host, call_773545.base,
                         call_773545.route, valid.getOrDefault("path"))
  result = hook(call_773545, url, valid)

proc call*(call_773546: Call_ListDeliverabilityTestReports_773533;
          PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listDeliverabilityTestReports
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  var query_773547 = newJObject()
  add(query_773547, "PageSize", newJInt(PageSize))
  add(query_773547, "NextToken", newJString(NextToken))
  result = call_773546.call(nil, query_773547, nil, nil, nil)

var listDeliverabilityTestReports* = Call_ListDeliverabilityTestReports_773533(
    name: "listDeliverabilityTestReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports",
    validator: validate_ListDeliverabilityTestReports_773534, base: "/",
    url: url_ListDeliverabilityTestReports_773535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainDeliverabilityCampaigns_773548 = ref object of OpenApiRestCall_772581
proc url_ListDomainDeliverabilityCampaigns_773550(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDomainDeliverabilityCampaigns_773549(path: JsonNode;
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
  var valid_773551 = path.getOrDefault("SubscribedDomain")
  valid_773551 = validateParameter(valid_773551, JString, required = true,
                                 default = nil)
  if valid_773551 != nil:
    section.add "SubscribedDomain", valid_773551
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   PageSize: JInt
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   StartDate: JString (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_773552 = query.getOrDefault("EndDate")
  valid_773552 = validateParameter(valid_773552, JString, required = true,
                                 default = nil)
  if valid_773552 != nil:
    section.add "EndDate", valid_773552
  var valid_773553 = query.getOrDefault("PageSize")
  valid_773553 = validateParameter(valid_773553, JInt, required = false, default = nil)
  if valid_773553 != nil:
    section.add "PageSize", valid_773553
  var valid_773554 = query.getOrDefault("NextToken")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "NextToken", valid_773554
  var valid_773555 = query.getOrDefault("StartDate")
  valid_773555 = validateParameter(valid_773555, JString, required = true,
                                 default = nil)
  if valid_773555 != nil:
    section.add "StartDate", valid_773555
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
  var valid_773556 = header.getOrDefault("X-Amz-Date")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-Date", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Security-Token")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Security-Token", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Content-Sha256", valid_773558
  var valid_773559 = header.getOrDefault("X-Amz-Algorithm")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Algorithm", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-Signature")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Signature", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-SignedHeaders", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Credential")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Credential", valid_773562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773563: Call_ListDomainDeliverabilityCampaigns_773548;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ## 
  let valid = call_773563.validator(path, query, header, formData, body)
  let scheme = call_773563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773563.url(scheme.get, call_773563.host, call_773563.base,
                         call_773563.route, valid.getOrDefault("path"))
  result = hook(call_773563, url, valid)

proc call*(call_773564: Call_ListDomainDeliverabilityCampaigns_773548;
          EndDate: string; SubscribedDomain: string; StartDate: string;
          PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listDomainDeliverabilityCampaigns
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ##   EndDate: string (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   PageSize: int
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   SubscribedDomain: string (required)
  ##                   : The domain to obtain deliverability data for.
  ##   StartDate: string (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  var path_773565 = newJObject()
  var query_773566 = newJObject()
  add(query_773566, "EndDate", newJString(EndDate))
  add(query_773566, "PageSize", newJInt(PageSize))
  add(query_773566, "NextToken", newJString(NextToken))
  add(path_773565, "SubscribedDomain", newJString(SubscribedDomain))
  add(query_773566, "StartDate", newJString(StartDate))
  result = call_773564.call(path_773565, query_773566, nil, nil, nil)

var listDomainDeliverabilityCampaigns* = Call_ListDomainDeliverabilityCampaigns_773548(
    name: "listDomainDeliverabilityCampaigns", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/domains/{SubscribedDomain}/campaigns#StartDate&EndDate",
    validator: validate_ListDomainDeliverabilityCampaigns_773549, base: "/",
    url: url_ListDomainDeliverabilityCampaigns_773550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773567 = ref object of OpenApiRestCall_772581
proc url_ListTagsForResource_773569(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_773568(path: JsonNode; query: JsonNode;
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
  var valid_773570 = query.getOrDefault("ResourceArn")
  valid_773570 = validateParameter(valid_773570, JString, required = true,
                                 default = nil)
  if valid_773570 != nil:
    section.add "ResourceArn", valid_773570
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
  var valid_773571 = header.getOrDefault("X-Amz-Date")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-Date", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Security-Token")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Security-Token", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Content-Sha256", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-Algorithm")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-Algorithm", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-Signature")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Signature", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-SignedHeaders", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Credential")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Credential", valid_773577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773578: Call_ListTagsForResource_773567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  let valid = call_773578.validator(path, query, header, formData, body)
  let scheme = call_773578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773578.url(scheme.get, call_773578.host, call_773578.base,
                         call_773578.route, valid.getOrDefault("path"))
  result = hook(call_773578, url, valid)

proc call*(call_773579: Call_ListTagsForResource_773567; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  var query_773580 = newJObject()
  add(query_773580, "ResourceArn", newJString(ResourceArn))
  result = call_773579.call(nil, query_773580, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_773567(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/tags#ResourceArn",
    validator: validate_ListTagsForResource_773568, base: "/",
    url: url_ListTagsForResource_773569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountDedicatedIpWarmupAttributes_773581 = ref object of OpenApiRestCall_772581
proc url_PutAccountDedicatedIpWarmupAttributes_773583(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAccountDedicatedIpWarmupAttributes_773582(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773584 = header.getOrDefault("X-Amz-Date")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Date", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Security-Token")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Security-Token", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Content-Sha256", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Algorithm")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Algorithm", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Signature")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Signature", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-SignedHeaders", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-Credential")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-Credential", valid_773590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773592: Call_PutAccountDedicatedIpWarmupAttributes_773581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ## 
  let valid = call_773592.validator(path, query, header, formData, body)
  let scheme = call_773592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773592.url(scheme.get, call_773592.host, call_773592.base,
                         call_773592.route, valid.getOrDefault("path"))
  result = hook(call_773592, url, valid)

proc call*(call_773593: Call_PutAccountDedicatedIpWarmupAttributes_773581;
          body: JsonNode): Recallable =
  ## putAccountDedicatedIpWarmupAttributes
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ##   body: JObject (required)
  var body_773594 = newJObject()
  if body != nil:
    body_773594 = body
  result = call_773593.call(nil, nil, nil, nil, body_773594)

var putAccountDedicatedIpWarmupAttributes* = Call_PutAccountDedicatedIpWarmupAttributes_773581(
    name: "putAccountDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/dedicated-ips/warmup",
    validator: validate_PutAccountDedicatedIpWarmupAttributes_773582, base: "/",
    url: url_PutAccountDedicatedIpWarmupAttributes_773583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSendingAttributes_773595 = ref object of OpenApiRestCall_772581
proc url_PutAccountSendingAttributes_773597(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAccountSendingAttributes_773596(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773598 = header.getOrDefault("X-Amz-Date")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Date", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Security-Token")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Security-Token", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Content-Sha256", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-Algorithm")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Algorithm", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Signature")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Signature", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-SignedHeaders", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Credential")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Credential", valid_773604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773606: Call_PutAccountSendingAttributes_773595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enable or disable the ability of your account to send email.
  ## 
  let valid = call_773606.validator(path, query, header, formData, body)
  let scheme = call_773606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773606.url(scheme.get, call_773606.host, call_773606.base,
                         call_773606.route, valid.getOrDefault("path"))
  result = hook(call_773606, url, valid)

proc call*(call_773607: Call_PutAccountSendingAttributes_773595; body: JsonNode): Recallable =
  ## putAccountSendingAttributes
  ## Enable or disable the ability of your account to send email.
  ##   body: JObject (required)
  var body_773608 = newJObject()
  if body != nil:
    body_773608 = body
  result = call_773607.call(nil, nil, nil, nil, body_773608)

var putAccountSendingAttributes* = Call_PutAccountSendingAttributes_773595(
    name: "putAccountSendingAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/sending",
    validator: validate_PutAccountSendingAttributes_773596, base: "/",
    url: url_PutAccountSendingAttributes_773597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetDeliveryOptions_773609 = ref object of OpenApiRestCall_772581
proc url_PutConfigurationSetDeliveryOptions_773611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutConfigurationSetDeliveryOptions_773610(path: JsonNode;
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
  var valid_773612 = path.getOrDefault("ConfigurationSetName")
  valid_773612 = validateParameter(valid_773612, JString, required = true,
                                 default = nil)
  if valid_773612 != nil:
    section.add "ConfigurationSetName", valid_773612
  result.add "path", section
  section = newJObject()
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
  var valid_773613 = header.getOrDefault("X-Amz-Date")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Date", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Security-Token")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Security-Token", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Content-Sha256", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-Algorithm")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Algorithm", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Signature")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Signature", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-SignedHeaders", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-Credential")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Credential", valid_773619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773621: Call_PutConfigurationSetDeliveryOptions_773609;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  let valid = call_773621.validator(path, query, header, formData, body)
  let scheme = call_773621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773621.url(scheme.get, call_773621.host, call_773621.base,
                         call_773621.route, valid.getOrDefault("path"))
  result = hook(call_773621, url, valid)

proc call*(call_773622: Call_PutConfigurationSetDeliveryOptions_773609;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetDeliveryOptions
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_773623 = newJObject()
  var body_773624 = newJObject()
  add(path_773623, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_773624 = body
  result = call_773622.call(path_773623, nil, nil, nil, body_773624)

var putConfigurationSetDeliveryOptions* = Call_PutConfigurationSetDeliveryOptions_773609(
    name: "putConfigurationSetDeliveryOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/delivery-options",
    validator: validate_PutConfigurationSetDeliveryOptions_773610, base: "/",
    url: url_PutConfigurationSetDeliveryOptions_773611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetReputationOptions_773625 = ref object of OpenApiRestCall_772581
proc url_PutConfigurationSetReputationOptions_773627(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutConfigurationSetReputationOptions_773626(path: JsonNode;
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
  var valid_773628 = path.getOrDefault("ConfigurationSetName")
  valid_773628 = validateParameter(valid_773628, JString, required = true,
                                 default = nil)
  if valid_773628 != nil:
    section.add "ConfigurationSetName", valid_773628
  result.add "path", section
  section = newJObject()
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
  var valid_773629 = header.getOrDefault("X-Amz-Date")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Date", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Security-Token")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Security-Token", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-Content-Sha256", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Algorithm")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Algorithm", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Signature")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Signature", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-SignedHeaders", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-Credential")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-Credential", valid_773635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773637: Call_PutConfigurationSetReputationOptions_773625;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_773637.validator(path, query, header, formData, body)
  let scheme = call_773637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773637.url(scheme.get, call_773637.host, call_773637.base,
                         call_773637.route, valid.getOrDefault("path"))
  result = hook(call_773637, url, valid)

proc call*(call_773638: Call_PutConfigurationSetReputationOptions_773625;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetReputationOptions
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_773639 = newJObject()
  var body_773640 = newJObject()
  add(path_773639, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_773640 = body
  result = call_773638.call(path_773639, nil, nil, nil, body_773640)

var putConfigurationSetReputationOptions* = Call_PutConfigurationSetReputationOptions_773625(
    name: "putConfigurationSetReputationOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/reputation-options",
    validator: validate_PutConfigurationSetReputationOptions_773626, base: "/",
    url: url_PutConfigurationSetReputationOptions_773627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSendingOptions_773641 = ref object of OpenApiRestCall_772581
proc url_PutConfigurationSetSendingOptions_773643(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutConfigurationSetSendingOptions_773642(path: JsonNode;
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
  var valid_773644 = path.getOrDefault("ConfigurationSetName")
  valid_773644 = validateParameter(valid_773644, JString, required = true,
                                 default = nil)
  if valid_773644 != nil:
    section.add "ConfigurationSetName", valid_773644
  result.add "path", section
  section = newJObject()
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
  var valid_773645 = header.getOrDefault("X-Amz-Date")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Date", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-Security-Token")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Security-Token", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Content-Sha256", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Algorithm")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Algorithm", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Signature")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Signature", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-SignedHeaders", valid_773650
  var valid_773651 = header.getOrDefault("X-Amz-Credential")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-Credential", valid_773651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773653: Call_PutConfigurationSetSendingOptions_773641;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_773653.validator(path, query, header, formData, body)
  let scheme = call_773653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773653.url(scheme.get, call_773653.host, call_773653.base,
                         call_773653.route, valid.getOrDefault("path"))
  result = hook(call_773653, url, valid)

proc call*(call_773654: Call_PutConfigurationSetSendingOptions_773641;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSendingOptions
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_773655 = newJObject()
  var body_773656 = newJObject()
  add(path_773655, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_773656 = body
  result = call_773654.call(path_773655, nil, nil, nil, body_773656)

var putConfigurationSetSendingOptions* = Call_PutConfigurationSetSendingOptions_773641(
    name: "putConfigurationSetSendingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}/sending",
    validator: validate_PutConfigurationSetSendingOptions_773642, base: "/",
    url: url_PutConfigurationSetSendingOptions_773643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetTrackingOptions_773657 = ref object of OpenApiRestCall_772581
proc url_PutConfigurationSetTrackingOptions_773659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutConfigurationSetTrackingOptions_773658(path: JsonNode;
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
  var valid_773660 = path.getOrDefault("ConfigurationSetName")
  valid_773660 = validateParameter(valid_773660, JString, required = true,
                                 default = nil)
  if valid_773660 != nil:
    section.add "ConfigurationSetName", valid_773660
  result.add "path", section
  section = newJObject()
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
  var valid_773661 = header.getOrDefault("X-Amz-Date")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Date", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Security-Token")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Security-Token", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Content-Sha256", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Algorithm")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Algorithm", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Signature")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Signature", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-SignedHeaders", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Credential")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Credential", valid_773667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773669: Call_PutConfigurationSetTrackingOptions_773657;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ## 
  let valid = call_773669.validator(path, query, header, formData, body)
  let scheme = call_773669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773669.url(scheme.get, call_773669.host, call_773669.base,
                         call_773669.route, valid.getOrDefault("path"))
  result = hook(call_773669, url, valid)

proc call*(call_773670: Call_PutConfigurationSetTrackingOptions_773657;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetTrackingOptions
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_773671 = newJObject()
  var body_773672 = newJObject()
  add(path_773671, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_773672 = body
  result = call_773670.call(path_773671, nil, nil, nil, body_773672)

var putConfigurationSetTrackingOptions* = Call_PutConfigurationSetTrackingOptions_773657(
    name: "putConfigurationSetTrackingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/tracking-options",
    validator: validate_PutConfigurationSetTrackingOptions_773658, base: "/",
    url: url_PutConfigurationSetTrackingOptions_773659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpInPool_773673 = ref object of OpenApiRestCall_772581
proc url_PutDedicatedIpInPool_773675(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/pool")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutDedicatedIpInPool_773674(path: JsonNode; query: JsonNode;
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
  var valid_773676 = path.getOrDefault("IP")
  valid_773676 = validateParameter(valid_773676, JString, required = true,
                                 default = nil)
  if valid_773676 != nil:
    section.add "IP", valid_773676
  result.add "path", section
  section = newJObject()
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773685: Call_PutDedicatedIpInPool_773673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  let valid = call_773685.validator(path, query, header, formData, body)
  let scheme = call_773685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773685.url(scheme.get, call_773685.host, call_773685.base,
                         call_773685.route, valid.getOrDefault("path"))
  result = hook(call_773685, url, valid)

proc call*(call_773686: Call_PutDedicatedIpInPool_773673; IP: string; body: JsonNode): Recallable =
  ## putDedicatedIpInPool
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_773687 = newJObject()
  var body_773688 = newJObject()
  add(path_773687, "IP", newJString(IP))
  if body != nil:
    body_773688 = body
  result = call_773686.call(path_773687, nil, nil, nil, body_773688)

var putDedicatedIpInPool* = Call_PutDedicatedIpInPool_773673(
    name: "putDedicatedIpInPool", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/pool",
    validator: validate_PutDedicatedIpInPool_773674, base: "/",
    url: url_PutDedicatedIpInPool_773675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpWarmupAttributes_773689 = ref object of OpenApiRestCall_772581
proc url_PutDedicatedIpWarmupAttributes_773691(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/warmup")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutDedicatedIpWarmupAttributes_773690(path: JsonNode;
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
  var valid_773692 = path.getOrDefault("IP")
  valid_773692 = validateParameter(valid_773692, JString, required = true,
                                 default = nil)
  if valid_773692 != nil:
    section.add "IP", valid_773692
  result.add "path", section
  section = newJObject()
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
  var valid_773693 = header.getOrDefault("X-Amz-Date")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Date", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Security-Token")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Security-Token", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Content-Sha256", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Algorithm")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Algorithm", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-Signature")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-Signature", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-SignedHeaders", valid_773698
  var valid_773699 = header.getOrDefault("X-Amz-Credential")
  valid_773699 = validateParameter(valid_773699, JString, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "X-Amz-Credential", valid_773699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773701: Call_PutDedicatedIpWarmupAttributes_773689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_773701.validator(path, query, header, formData, body)
  let scheme = call_773701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773701.url(scheme.get, call_773701.host, call_773701.base,
                         call_773701.route, valid.getOrDefault("path"))
  result = hook(call_773701, url, valid)

proc call*(call_773702: Call_PutDedicatedIpWarmupAttributes_773689; IP: string;
          body: JsonNode): Recallable =
  ## putDedicatedIpWarmupAttributes
  ## <p/>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_773703 = newJObject()
  var body_773704 = newJObject()
  add(path_773703, "IP", newJString(IP))
  if body != nil:
    body_773704 = body
  result = call_773702.call(path_773703, nil, nil, nil, body_773704)

var putDedicatedIpWarmupAttributes* = Call_PutDedicatedIpWarmupAttributes_773689(
    name: "putDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/warmup",
    validator: validate_PutDedicatedIpWarmupAttributes_773690, base: "/",
    url: url_PutDedicatedIpWarmupAttributes_773691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimAttributes_773705 = ref object of OpenApiRestCall_772581
proc url_PutEmailIdentityDkimAttributes_773707(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/dkim")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutEmailIdentityDkimAttributes_773706(path: JsonNode;
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
  var valid_773708 = path.getOrDefault("EmailIdentity")
  valid_773708 = validateParameter(valid_773708, JString, required = true,
                                 default = nil)
  if valid_773708 != nil:
    section.add "EmailIdentity", valid_773708
  result.add "path", section
  section = newJObject()
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
  var valid_773709 = header.getOrDefault("X-Amz-Date")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Date", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Security-Token")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Security-Token", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Content-Sha256", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-Algorithm")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Algorithm", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-Signature")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Signature", valid_773713
  var valid_773714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-SignedHeaders", valid_773714
  var valid_773715 = header.getOrDefault("X-Amz-Credential")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Credential", valid_773715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773717: Call_PutEmailIdentityDkimAttributes_773705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to enable or disable DKIM authentication for an email identity.
  ## 
  let valid = call_773717.validator(path, query, header, formData, body)
  let scheme = call_773717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773717.url(scheme.get, call_773717.host, call_773717.base,
                         call_773717.route, valid.getOrDefault("path"))
  result = hook(call_773717, url, valid)

proc call*(call_773718: Call_PutEmailIdentityDkimAttributes_773705;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityDkimAttributes
  ## Used to enable or disable DKIM authentication for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to change the DKIM settings for.
  ##   body: JObject (required)
  var path_773719 = newJObject()
  var body_773720 = newJObject()
  add(path_773719, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_773720 = body
  result = call_773718.call(path_773719, nil, nil, nil, body_773720)

var putEmailIdentityDkimAttributes* = Call_PutEmailIdentityDkimAttributes_773705(
    name: "putEmailIdentityDkimAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/dkim",
    validator: validate_PutEmailIdentityDkimAttributes_773706, base: "/",
    url: url_PutEmailIdentityDkimAttributes_773707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityFeedbackAttributes_773721 = ref object of OpenApiRestCall_772581
proc url_PutEmailIdentityFeedbackAttributes_773723(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/feedback")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutEmailIdentityFeedbackAttributes_773722(path: JsonNode;
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
  var valid_773724 = path.getOrDefault("EmailIdentity")
  valid_773724 = validateParameter(valid_773724, JString, required = true,
                                 default = nil)
  if valid_773724 != nil:
    section.add "EmailIdentity", valid_773724
  result.add "path", section
  section = newJObject()
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
  var valid_773725 = header.getOrDefault("X-Amz-Date")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Date", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-Security-Token")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-Security-Token", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Content-Sha256", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-Algorithm")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Algorithm", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-Signature")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-Signature", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-SignedHeaders", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Credential")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Credential", valid_773731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773733: Call_PutEmailIdentityFeedbackAttributes_773721;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  let valid = call_773733.validator(path, query, header, formData, body)
  let scheme = call_773733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773733.url(scheme.get, call_773733.host, call_773733.base,
                         call_773733.route, valid.getOrDefault("path"))
  result = hook(call_773733, url, valid)

proc call*(call_773734: Call_PutEmailIdentityFeedbackAttributes_773721;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityFeedbackAttributes
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  ##   body: JObject (required)
  var path_773735 = newJObject()
  var body_773736 = newJObject()
  add(path_773735, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_773736 = body
  result = call_773734.call(path_773735, nil, nil, nil, body_773736)

var putEmailIdentityFeedbackAttributes* = Call_PutEmailIdentityFeedbackAttributes_773721(
    name: "putEmailIdentityFeedbackAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/feedback",
    validator: validate_PutEmailIdentityFeedbackAttributes_773722, base: "/",
    url: url_PutEmailIdentityFeedbackAttributes_773723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityMailFromAttributes_773737 = ref object of OpenApiRestCall_772581
proc url_PutEmailIdentityMailFromAttributes_773739(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/mail-from")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutEmailIdentityMailFromAttributes_773738(path: JsonNode;
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
  var valid_773740 = path.getOrDefault("EmailIdentity")
  valid_773740 = validateParameter(valid_773740, JString, required = true,
                                 default = nil)
  if valid_773740 != nil:
    section.add "EmailIdentity", valid_773740
  result.add "path", section
  section = newJObject()
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
  var valid_773741 = header.getOrDefault("X-Amz-Date")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-Date", valid_773741
  var valid_773742 = header.getOrDefault("X-Amz-Security-Token")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "X-Amz-Security-Token", valid_773742
  var valid_773743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-Content-Sha256", valid_773743
  var valid_773744 = header.getOrDefault("X-Amz-Algorithm")
  valid_773744 = validateParameter(valid_773744, JString, required = false,
                                 default = nil)
  if valid_773744 != nil:
    section.add "X-Amz-Algorithm", valid_773744
  var valid_773745 = header.getOrDefault("X-Amz-Signature")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Signature", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-SignedHeaders", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Credential")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Credential", valid_773747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773749: Call_PutEmailIdentityMailFromAttributes_773737;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ## 
  let valid = call_773749.validator(path, query, header, formData, body)
  let scheme = call_773749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773749.url(scheme.get, call_773749.host, call_773749.base,
                         call_773749.route, valid.getOrDefault("path"))
  result = hook(call_773749, url, valid)

proc call*(call_773750: Call_PutEmailIdentityMailFromAttributes_773737;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityMailFromAttributes
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  ##   body: JObject (required)
  var path_773751 = newJObject()
  var body_773752 = newJObject()
  add(path_773751, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_773752 = body
  result = call_773750.call(path_773751, nil, nil, nil, body_773752)

var putEmailIdentityMailFromAttributes* = Call_PutEmailIdentityMailFromAttributes_773737(
    name: "putEmailIdentityMailFromAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/mail-from",
    validator: validate_PutEmailIdentityMailFromAttributes_773738, base: "/",
    url: url_PutEmailIdentityMailFromAttributes_773739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEmail_773753 = ref object of OpenApiRestCall_772581
proc url_SendEmail_773755(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendEmail_773754(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773756 = header.getOrDefault("X-Amz-Date")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-Date", valid_773756
  var valid_773757 = header.getOrDefault("X-Amz-Security-Token")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amz-Security-Token", valid_773757
  var valid_773758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "X-Amz-Content-Sha256", valid_773758
  var valid_773759 = header.getOrDefault("X-Amz-Algorithm")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-Algorithm", valid_773759
  var valid_773760 = header.getOrDefault("X-Amz-Signature")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Signature", valid_773760
  var valid_773761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-SignedHeaders", valid_773761
  var valid_773762 = header.getOrDefault("X-Amz-Credential")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-Credential", valid_773762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773764: Call_SendEmail_773753; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  let valid = call_773764.validator(path, query, header, formData, body)
  let scheme = call_773764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773764.url(scheme.get, call_773764.host, call_773764.base,
                         call_773764.route, valid.getOrDefault("path"))
  result = hook(call_773764, url, valid)

proc call*(call_773765: Call_SendEmail_773753; body: JsonNode): Recallable =
  ## sendEmail
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ##   body: JObject (required)
  var body_773766 = newJObject()
  if body != nil:
    body_773766 = body
  result = call_773765.call(nil, nil, nil, nil, body_773766)

var sendEmail* = Call_SendEmail_773753(name: "sendEmail", meth: HttpMethod.HttpPost,
                                    host: "email.amazonaws.com",
                                    route: "/v1/email/outbound-emails",
                                    validator: validate_SendEmail_773754,
                                    base: "/", url: url_SendEmail_773755,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773767 = ref object of OpenApiRestCall_772581
proc url_TagResource_773769(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_773768(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773770 = header.getOrDefault("X-Amz-Date")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Date", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Security-Token")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Security-Token", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Content-Sha256", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-Algorithm")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-Algorithm", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-Signature")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-Signature", valid_773774
  var valid_773775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-SignedHeaders", valid_773775
  var valid_773776 = header.getOrDefault("X-Amz-Credential")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Credential", valid_773776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773778: Call_TagResource_773767; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  let valid = call_773778.validator(path, query, header, formData, body)
  let scheme = call_773778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773778.url(scheme.get, call_773778.host, call_773778.base,
                         call_773778.route, valid.getOrDefault("path"))
  result = hook(call_773778, url, valid)

proc call*(call_773779: Call_TagResource_773767; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   body: JObject (required)
  var body_773780 = newJObject()
  if body != nil:
    body_773780 = body
  result = call_773779.call(nil, nil, nil, nil, body_773780)

var tagResource* = Call_TagResource_773767(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "email.amazonaws.com",
                                        route: "/v1/email/tags",
                                        validator: validate_TagResource_773768,
                                        base: "/", url: url_TagResource_773769,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773781 = ref object of OpenApiRestCall_772581
proc url_UntagResource_773783(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_773782(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_773784 = query.getOrDefault("ResourceArn")
  valid_773784 = validateParameter(valid_773784, JString, required = true,
                                 default = nil)
  if valid_773784 != nil:
    section.add "ResourceArn", valid_773784
  var valid_773785 = query.getOrDefault("TagKeys")
  valid_773785 = validateParameter(valid_773785, JArray, required = true, default = nil)
  if valid_773785 != nil:
    section.add "TagKeys", valid_773785
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
  var valid_773786 = header.getOrDefault("X-Amz-Date")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Date", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Security-Token")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Security-Token", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Content-Sha256", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-Algorithm")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-Algorithm", valid_773789
  var valid_773790 = header.getOrDefault("X-Amz-Signature")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Signature", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-SignedHeaders", valid_773791
  var valid_773792 = header.getOrDefault("X-Amz-Credential")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "X-Amz-Credential", valid_773792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773793: Call_UntagResource_773781; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  let valid = call_773793.validator(path, query, header, formData, body)
  let scheme = call_773793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773793.url(scheme.get, call_773793.host, call_773793.base,
                         call_773793.route, valid.getOrDefault("path"))
  result = hook(call_773793, url, valid)

proc call*(call_773794: Call_UntagResource_773781; ResourceArn: string;
          TagKeys: JsonNode): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  var query_773795 = newJObject()
  add(query_773795, "ResourceArn", newJString(ResourceArn))
  if TagKeys != nil:
    query_773795.add "TagKeys", TagKeys
  result = call_773794.call(nil, query_773795, nil, nil, nil)

var untagResource* = Call_UntagResource_773781(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "email.amazonaws.com",
    route: "/v1/email/tags#ResourceArn&TagKeys",
    validator: validate_UntagResource_773782, base: "/", url: url_UntagResource_773783,
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
