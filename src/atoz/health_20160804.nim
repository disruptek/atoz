
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Health APIs and Notifications
## version: 2016-08-04
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Health</fullname> <p>The AWS Health API provides programmatic access to the AWS Health information that is presented in the <a href="https://phd.aws.amazon.com/phd/home#/">AWS Personal Health Dashboard</a>. You can get information about events that affect your AWS resources:</p> <ul> <li> <p> <a>DescribeEvents</a>: Summary information about events.</p> </li> <li> <p> <a>DescribeEventDetails</a>: Detailed information about one or more events.</p> </li> <li> <p> <a>DescribeAffectedEntities</a>: Information about AWS resources that are affected by one or more events.</p> </li> </ul> <p>In addition, these operations provide information about event types and summary counts of events or affected entities:</p> <ul> <li> <p> <a>DescribeEventTypes</a>: Information about the kinds of events that AWS Health tracks.</p> </li> <li> <p> <a>DescribeEventAggregates</a>: A count of the number of events that meet specified criteria.</p> </li> <li> <p> <a>DescribeEntityAggregates</a>: A count of the number of affected entities that meet specified criteria.</p> </li> </ul> <p>The Health API requires a Business or Enterprise support plan from <a href="http://aws.amazon.com/premiumsupport/">AWS Support</a>. Calling the Health API from an account that does not have a Business or Enterprise support plan causes a <code>SubscriptionRequiredException</code>. </p> <p>For authentication of requests, AWS Health uses the <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4 Signing Process</a>.</p> <p>See the <a href="https://docs.aws.amazon.com/health/latest/ug/what-is-aws-health.html">AWS Health User Guide</a> for information about how to use the API.</p> <p> <b>Service Endpoint</b> </p> <p>The HTTP endpoint for the AWS Health API is:</p> <ul> <li> <p>https://health.us-east-1.amazonaws.com </p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/health/
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "health"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_DescribeAffectedEntities_772933 = ref object of OpenApiRestCall_772597
proc url_DescribeAffectedEntities_772935(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAffectedEntities_772934(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_773047 = query.getOrDefault("maxResults")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "maxResults", valid_773047
  var valid_773048 = query.getOrDefault("nextToken")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "nextToken", valid_773048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773049 = header.getOrDefault("X-Amz-Date")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Date", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Security-Token")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Security-Token", valid_773050
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773064 = header.getOrDefault("X-Amz-Target")
  valid_773064 = validateParameter(valid_773064, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntities"))
  if valid_773064 != nil:
    section.add "X-Amz-Target", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Content-Sha256", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Algorithm")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Algorithm", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Signature")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Signature", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-SignedHeaders", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-Credential")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-Credential", valid_773069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773093: Call_DescribeAffectedEntities_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  let valid = call_773093.validator(path, query, header, formData, body)
  let scheme = call_773093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773093.url(scheme.get, call_773093.host, call_773093.base,
                         call_773093.route, valid.getOrDefault("path"))
  result = hook(call_773093, url, valid)

proc call*(call_773164: Call_DescribeAffectedEntities_772933; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeAffectedEntities
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773165 = newJObject()
  var body_773167 = newJObject()
  add(query_773165, "maxResults", newJString(maxResults))
  add(query_773165, "nextToken", newJString(nextToken))
  if body != nil:
    body_773167 = body
  result = call_773164.call(nil, query_773165, nil, nil, body_773167)

var describeAffectedEntities* = Call_DescribeAffectedEntities_772933(
    name: "describeAffectedEntities", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntities",
    validator: validate_DescribeAffectedEntities_772934, base: "/",
    url: url_DescribeAffectedEntities_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityAggregates_773206 = ref object of OpenApiRestCall_772597
proc url_DescribeEntityAggregates_773208(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEntityAggregates_773207(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773209 = header.getOrDefault("X-Amz-Date")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Date", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Security-Token")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Security-Token", valid_773210
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773211 = header.getOrDefault("X-Amz-Target")
  valid_773211 = validateParameter(valid_773211, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEntityAggregates"))
  if valid_773211 != nil:
    section.add "X-Amz-Target", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Content-Sha256", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Algorithm")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Algorithm", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Signature")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Signature", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-SignedHeaders", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Credential")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Credential", valid_773216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773218: Call_DescribeEntityAggregates_773206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ## 
  let valid = call_773218.validator(path, query, header, formData, body)
  let scheme = call_773218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773218.url(scheme.get, call_773218.host, call_773218.base,
                         call_773218.route, valid.getOrDefault("path"))
  result = hook(call_773218, url, valid)

proc call*(call_773219: Call_DescribeEntityAggregates_773206; body: JsonNode): Recallable =
  ## describeEntityAggregates
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ##   body: JObject (required)
  var body_773220 = newJObject()
  if body != nil:
    body_773220 = body
  result = call_773219.call(nil, nil, nil, nil, body_773220)

var describeEntityAggregates* = Call_DescribeEntityAggregates_773206(
    name: "describeEntityAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEntityAggregates",
    validator: validate_DescribeEntityAggregates_773207, base: "/",
    url: url_DescribeEntityAggregates_773208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventAggregates_773221 = ref object of OpenApiRestCall_772597
proc url_DescribeEventAggregates_773223(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEventAggregates_773222(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_773224 = query.getOrDefault("maxResults")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "maxResults", valid_773224
  var valid_773225 = query.getOrDefault("nextToken")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "nextToken", valid_773225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773226 = header.getOrDefault("X-Amz-Date")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Date", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Security-Token")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Security-Token", valid_773227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773228 = header.getOrDefault("X-Amz-Target")
  valid_773228 = validateParameter(valid_773228, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventAggregates"))
  if valid_773228 != nil:
    section.add "X-Amz-Target", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Content-Sha256", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Algorithm")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Algorithm", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Signature")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Signature", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-SignedHeaders", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Credential")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Credential", valid_773233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773235: Call_DescribeEventAggregates_773221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  let valid = call_773235.validator(path, query, header, formData, body)
  let scheme = call_773235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773235.url(scheme.get, call_773235.host, call_773235.base,
                         call_773235.route, valid.getOrDefault("path"))
  result = hook(call_773235, url, valid)

proc call*(call_773236: Call_DescribeEventAggregates_773221; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEventAggregates
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773237 = newJObject()
  var body_773238 = newJObject()
  add(query_773237, "maxResults", newJString(maxResults))
  add(query_773237, "nextToken", newJString(nextToken))
  if body != nil:
    body_773238 = body
  result = call_773236.call(nil, query_773237, nil, nil, body_773238)

var describeEventAggregates* = Call_DescribeEventAggregates_773221(
    name: "describeEventAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventAggregates",
    validator: validate_DescribeEventAggregates_773222, base: "/",
    url: url_DescribeEventAggregates_773223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetails_773239 = ref object of OpenApiRestCall_772597
proc url_DescribeEventDetails_773241(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEventDetails_773240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, etc., as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773242 = header.getOrDefault("X-Amz-Date")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Date", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Security-Token")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Security-Token", valid_773243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773244 = header.getOrDefault("X-Amz-Target")
  valid_773244 = validateParameter(valid_773244, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetails"))
  if valid_773244 != nil:
    section.add "X-Amz-Target", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Content-Sha256", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Algorithm")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Algorithm", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Signature")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Signature", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-SignedHeaders", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Credential")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Credential", valid_773249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773251: Call_DescribeEventDetails_773239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, etc., as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ## 
  let valid = call_773251.validator(path, query, header, formData, body)
  let scheme = call_773251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773251.url(scheme.get, call_773251.host, call_773251.base,
                         call_773251.route, valid.getOrDefault("path"))
  result = hook(call_773251, url, valid)

proc call*(call_773252: Call_DescribeEventDetails_773239; body: JsonNode): Recallable =
  ## describeEventDetails
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, etc., as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ##   body: JObject (required)
  var body_773253 = newJObject()
  if body != nil:
    body_773253 = body
  result = call_773252.call(nil, nil, nil, nil, body_773253)

var describeEventDetails* = Call_DescribeEventDetails_773239(
    name: "describeEventDetails", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetails",
    validator: validate_DescribeEventDetails_773240, base: "/",
    url: url_DescribeEventDetails_773241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTypes_773254 = ref object of OpenApiRestCall_772597
proc url_DescribeEventTypes_773256(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEventTypes_773255(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_773257 = query.getOrDefault("maxResults")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "maxResults", valid_773257
  var valid_773258 = query.getOrDefault("nextToken")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "nextToken", valid_773258
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773259 = header.getOrDefault("X-Amz-Date")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Date", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Security-Token")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Security-Token", valid_773260
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773261 = header.getOrDefault("X-Amz-Target")
  valid_773261 = validateParameter(valid_773261, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventTypes"))
  if valid_773261 != nil:
    section.add "X-Amz-Target", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Content-Sha256", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Algorithm")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Algorithm", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-Signature")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Signature", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-SignedHeaders", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Credential")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Credential", valid_773266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773268: Call_DescribeEventTypes_773254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  let valid = call_773268.validator(path, query, header, formData, body)
  let scheme = call_773268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773268.url(scheme.get, call_773268.host, call_773268.base,
                         call_773268.route, valid.getOrDefault("path"))
  result = hook(call_773268, url, valid)

proc call*(call_773269: Call_DescribeEventTypes_773254; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEventTypes
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773270 = newJObject()
  var body_773271 = newJObject()
  add(query_773270, "maxResults", newJString(maxResults))
  add(query_773270, "nextToken", newJString(nextToken))
  if body != nil:
    body_773271 = body
  result = call_773269.call(nil, query_773270, nil, nil, body_773271)

var describeEventTypes* = Call_DescribeEventTypes_773254(
    name: "describeEventTypes", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventTypes",
    validator: validate_DescribeEventTypes_773255, base: "/",
    url: url_DescribeEventTypes_773256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_773272 = ref object of OpenApiRestCall_772597
proc url_DescribeEvents_773274(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEvents_773273(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_773275 = query.getOrDefault("maxResults")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "maxResults", valid_773275
  var valid_773276 = query.getOrDefault("nextToken")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "nextToken", valid_773276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773277 = header.getOrDefault("X-Amz-Date")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Date", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Security-Token")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Security-Token", valid_773278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773279 = header.getOrDefault("X-Amz-Target")
  valid_773279 = validateParameter(valid_773279, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEvents"))
  if valid_773279 != nil:
    section.add "X-Amz-Target", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Content-Sha256", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Algorithm")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Algorithm", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Signature")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Signature", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-SignedHeaders", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Credential")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Credential", valid_773284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773286: Call_DescribeEvents_773272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  let valid = call_773286.validator(path, query, header, formData, body)
  let scheme = call_773286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773286.url(scheme.get, call_773286.host, call_773286.base,
                         call_773286.route, valid.getOrDefault("path"))
  result = hook(call_773286, url, valid)

proc call*(call_773287: Call_DescribeEvents_773272; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEvents
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773288 = newJObject()
  var body_773289 = newJObject()
  add(query_773288, "maxResults", newJString(maxResults))
  add(query_773288, "nextToken", newJString(nextToken))
  if body != nil:
    body_773289 = body
  result = call_773287.call(nil, query_773288, nil, nil, body_773289)

var describeEvents* = Call_DescribeEvents_773272(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEvents",
    validator: validate_DescribeEvents_773273, base: "/", url: url_DescribeEvents_773274,
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
