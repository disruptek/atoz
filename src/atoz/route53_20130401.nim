
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Route 53
## version: 2013-04-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Route 53 is a highly available and scalable Domain Name System (DNS) web service.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/route53/
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "route53"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateVPCWithHostedZone_612996 = ref object of OpenApiRestCall_612658
proc url_AssociateVPCWithHostedZone_612998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/associatevpc")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateVPCWithHostedZone_612997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : <p>The ID of the private hosted zone that you want to associate an Amazon VPC with.</p> <p>Note that you can't associate a VPC with a hosted zone that doesn't have an existing VPC association.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613124 = path.getOrDefault("Id")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "Id", valid_613124
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
  var valid_613125 = header.getOrDefault("X-Amz-Signature")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Signature", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Content-Sha256", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Date")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Date", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Credential")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Credential", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Security-Token")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Security-Token", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Algorithm")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Algorithm", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-SignedHeaders", valid_613131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613155: Call_AssociateVPCWithHostedZone_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_AssociateVPCWithHostedZone_612996; body: JsonNode;
          Id: string): Recallable =
  ## associateVPCWithHostedZone
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : <p>The ID of the private hosted zone that you want to associate an Amazon VPC with.</p> <p>Note that you can't associate a VPC with a hosted zone that doesn't have an existing VPC association.</p>
  var path_613227 = newJObject()
  var body_613229 = newJObject()
  if body != nil:
    body_613229 = body
  add(path_613227, "Id", newJString(Id))
  result = call_613226.call(path_613227, nil, nil, nil, body_613229)

var associateVPCWithHostedZone* = Call_AssociateVPCWithHostedZone_612996(
    name: "associateVPCWithHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/associatevpc",
    validator: validate_AssociateVPCWithHostedZone_612997, base: "/",
    url: url_AssociateVPCWithHostedZone_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeResourceRecordSets_613268 = ref object of OpenApiRestCall_612658
proc url_ChangeResourceRecordSets_613270(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/rrset/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ChangeResourceRecordSets_613269(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to change.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613271 = path.getOrDefault("Id")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = nil)
  if valid_613271 != nil:
    section.add "Id", valid_613271
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
  var valid_613272 = header.getOrDefault("X-Amz-Signature")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Signature", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Content-Sha256", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Date")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Date", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Credential")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Credential", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Security-Token")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Security-Token", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Algorithm")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Algorithm", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613280: Call_ChangeResourceRecordSets_613268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_613280.validator(path, query, header, formData, body)
  let scheme = call_613280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613280.url(scheme.get, call_613280.host, call_613280.base,
                         call_613280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613280, url, valid)

proc call*(call_613281: Call_ChangeResourceRecordSets_613268; body: JsonNode;
          Id: string): Recallable =
  ## changeResourceRecordSets
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to change.
  var path_613282 = newJObject()
  var body_613283 = newJObject()
  if body != nil:
    body_613283 = body
  add(path_613282, "Id", newJString(Id))
  result = call_613281.call(path_613282, nil, nil, nil, body_613283)

var changeResourceRecordSets* = Call_ChangeResourceRecordSets_613268(
    name: "changeResourceRecordSets", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset/",
    validator: validate_ChangeResourceRecordSets_613269, base: "/",
    url: url_ChangeResourceRecordSets_613270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeTagsForResource_613312 = ref object of OpenApiRestCall_612658
proc url_ChangeTagsForResource_613314(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ChangeTagsForResource_613313(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_613315 = path.getOrDefault("ResourceId")
  valid_613315 = validateParameter(valid_613315, JString, required = true,
                                 default = nil)
  if valid_613315 != nil:
    section.add "ResourceId", valid_613315
  var valid_613316 = path.getOrDefault("ResourceType")
  valid_613316 = validateParameter(valid_613316, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_613316 != nil:
    section.add "ResourceType", valid_613316
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
  var valid_613317 = header.getOrDefault("X-Amz-Signature")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Signature", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Content-Sha256", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Date")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Date", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Credential")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Credential", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Security-Token")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Security-Token", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Algorithm")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Algorithm", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-SignedHeaders", valid_613323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613325: Call_ChangeTagsForResource_613312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_613325.validator(path, query, header, formData, body)
  let scheme = call_613325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613325.url(scheme.get, call_613325.host, call_613325.base,
                         call_613325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613325, url, valid)

proc call*(call_613326: Call_ChangeTagsForResource_613312; ResourceId: string;
          body: JsonNode; ResourceType: string = "healthcheck"): Recallable =
  ## changeTagsForResource
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   body: JObject (required)
  var path_613327 = newJObject()
  var body_613328 = newJObject()
  add(path_613327, "ResourceId", newJString(ResourceId))
  add(path_613327, "ResourceType", newJString(ResourceType))
  if body != nil:
    body_613328 = body
  result = call_613326.call(path_613327, nil, nil, nil, body_613328)

var changeTagsForResource* = Call_ChangeTagsForResource_613312(
    name: "changeTagsForResource", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ChangeTagsForResource_613313, base: "/",
    url: url_ChangeTagsForResource_613314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613284 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613286(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_613285(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_613287 = path.getOrDefault("ResourceId")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "ResourceId", valid_613287
  var valid_613301 = path.getOrDefault("ResourceType")
  valid_613301 = validateParameter(valid_613301, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_613301 != nil:
    section.add "ResourceType", valid_613301
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
  var valid_613302 = header.getOrDefault("X-Amz-Signature")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Signature", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Content-Sha256", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Date")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Date", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Credential")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Credential", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Security-Token")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Security-Token", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Algorithm")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Algorithm", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-SignedHeaders", valid_613308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613309: Call_ListTagsForResource_613284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_613309.validator(path, query, header, formData, body)
  let scheme = call_613309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613309.url(scheme.get, call_613309.host, call_613309.base,
                         call_613309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613309, url, valid)

proc call*(call_613310: Call_ListTagsForResource_613284; ResourceId: string;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  var path_613311 = newJObject()
  add(path_613311, "ResourceId", newJString(ResourceId))
  add(path_613311, "ResourceType", newJString(ResourceType))
  result = call_613310.call(path_613311, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613284(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ListTagsForResource_613285, base: "/",
    url: url_ListTagsForResource_613286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHealthCheck_613346 = ref object of OpenApiRestCall_612658
proc url_CreateHealthCheck_613348(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHealthCheck_613347(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
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
  var valid_613349 = header.getOrDefault("X-Amz-Signature")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Signature", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Content-Sha256", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Date")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Date", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Credential")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Credential", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Security-Token")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Security-Token", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Algorithm")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Algorithm", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-SignedHeaders", valid_613355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613357: Call_CreateHealthCheck_613346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ## 
  let valid = call_613357.validator(path, query, header, formData, body)
  let scheme = call_613357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613357.url(scheme.get, call_613357.host, call_613357.base,
                         call_613357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613357, url, valid)

proc call*(call_613358: Call_CreateHealthCheck_613346; body: JsonNode): Recallable =
  ## createHealthCheck
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613359 = newJObject()
  if body != nil:
    body_613359 = body
  result = call_613358.call(nil, nil, nil, nil, body_613359)

var createHealthCheck* = Call_CreateHealthCheck_613346(name: "createHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_CreateHealthCheck_613347,
    base: "/", url: url_CreateHealthCheck_613348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHealthChecks_613329 = ref object of OpenApiRestCall_612658
proc url_ListHealthChecks_613331(protocol: Scheme; host: string; base: string;
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

proc validate_ListHealthChecks_613330(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   maxitems: JString
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  section = newJObject()
  var valid_613332 = query.getOrDefault("Marker")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "Marker", valid_613332
  var valid_613333 = query.getOrDefault("MaxItems")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "MaxItems", valid_613333
  var valid_613334 = query.getOrDefault("maxitems")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "maxitems", valid_613334
  var valid_613335 = query.getOrDefault("marker")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "marker", valid_613335
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
  var valid_613336 = header.getOrDefault("X-Amz-Signature")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Signature", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Content-Sha256", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Date")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Date", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Credential")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Credential", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Security-Token")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Security-Token", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Algorithm")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Algorithm", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-SignedHeaders", valid_613342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613343: Call_ListHealthChecks_613329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  let valid = call_613343.validator(path, query, header, formData, body)
  let scheme = call_613343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613343.url(scheme.get, call_613343.host, call_613343.base,
                         call_613343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613343, url, valid)

proc call*(call_613344: Call_ListHealthChecks_613329; Marker: string = "";
          MaxItems: string = ""; maxitems: string = ""; marker: string = ""): Recallable =
  ## listHealthChecks
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  ##   maxitems: string
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  var query_613345 = newJObject()
  add(query_613345, "Marker", newJString(Marker))
  add(query_613345, "MaxItems", newJString(MaxItems))
  add(query_613345, "maxitems", newJString(maxitems))
  add(query_613345, "marker", newJString(marker))
  result = call_613344.call(nil, query_613345, nil, nil, nil)

var listHealthChecks* = Call_ListHealthChecks_613329(name: "listHealthChecks",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_ListHealthChecks_613330,
    base: "/", url: url_ListHealthChecks_613331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHostedZone_613378 = ref object of OpenApiRestCall_612658
proc url_CreateHostedZone_613380(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHostedZone_613379(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
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
  var valid_613381 = header.getOrDefault("X-Amz-Signature")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Signature", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Content-Sha256", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Date")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Date", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Credential")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Credential", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Security-Token")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Security-Token", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Algorithm")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Algorithm", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-SignedHeaders", valid_613387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613389: Call_CreateHostedZone_613378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ## 
  let valid = call_613389.validator(path, query, header, formData, body)
  let scheme = call_613389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613389.url(scheme.get, call_613389.host, call_613389.base,
                         call_613389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613389, url, valid)

proc call*(call_613390: Call_CreateHostedZone_613378; body: JsonNode): Recallable =
  ## createHostedZone
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ##   body: JObject (required)
  var body_613391 = newJObject()
  if body != nil:
    body_613391 = body
  result = call_613390.call(nil, nil, nil, nil, body_613391)

var createHostedZone* = Call_CreateHostedZone_613378(name: "createHostedZone",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_CreateHostedZone_613379,
    base: "/", url: url_CreateHostedZone_613380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZones_613360 = ref object of OpenApiRestCall_612658
proc url_ListHostedZones_613362(protocol: Scheme; host: string; base: string;
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

proc validate_ListHostedZones_613361(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   maxitems: JString
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   delegationsetid: JString
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  section = newJObject()
  var valid_613363 = query.getOrDefault("Marker")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "Marker", valid_613363
  var valid_613364 = query.getOrDefault("MaxItems")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "MaxItems", valid_613364
  var valid_613365 = query.getOrDefault("maxitems")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "maxitems", valid_613365
  var valid_613366 = query.getOrDefault("delegationsetid")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "delegationsetid", valid_613366
  var valid_613367 = query.getOrDefault("marker")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "marker", valid_613367
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
  var valid_613368 = header.getOrDefault("X-Amz-Signature")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Signature", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Content-Sha256", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Date")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Date", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Credential")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Credential", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Security-Token")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Security-Token", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Algorithm")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Algorithm", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-SignedHeaders", valid_613374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613375: Call_ListHostedZones_613360; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_613375.validator(path, query, header, formData, body)
  let scheme = call_613375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613375.url(scheme.get, call_613375.host, call_613375.base,
                         call_613375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613375, url, valid)

proc call*(call_613376: Call_ListHostedZones_613360; Marker: string = "";
          MaxItems: string = ""; maxitems: string = ""; delegationsetid: string = "";
          marker: string = ""): Recallable =
  ## listHostedZones
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  ##   maxitems: string
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   delegationsetid: string
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  var query_613377 = newJObject()
  add(query_613377, "Marker", newJString(Marker))
  add(query_613377, "MaxItems", newJString(MaxItems))
  add(query_613377, "maxitems", newJString(maxitems))
  add(query_613377, "delegationsetid", newJString(delegationsetid))
  add(query_613377, "marker", newJString(marker))
  result = call_613376.call(nil, query_613377, nil, nil, nil)

var listHostedZones* = Call_ListHostedZones_613360(name: "listHostedZones",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_ListHostedZones_613361,
    base: "/", url: url_ListHostedZones_613362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueryLoggingConfig_613408 = ref object of OpenApiRestCall_612658
proc url_CreateQueryLoggingConfig_613410(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateQueryLoggingConfig_613409(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
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
  var valid_613411 = header.getOrDefault("X-Amz-Signature")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Signature", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Content-Sha256", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Date")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Date", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Credential")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Credential", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Security-Token")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Security-Token", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Algorithm")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Algorithm", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-SignedHeaders", valid_613417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613419: Call_CreateQueryLoggingConfig_613408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ## 
  let valid = call_613419.validator(path, query, header, formData, body)
  let scheme = call_613419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613419.url(scheme.get, call_613419.host, call_613419.base,
                         call_613419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613419, url, valid)

proc call*(call_613420: Call_CreateQueryLoggingConfig_613408; body: JsonNode): Recallable =
  ## createQueryLoggingConfig
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ##   body: JObject (required)
  var body_613421 = newJObject()
  if body != nil:
    body_613421 = body
  result = call_613420.call(nil, nil, nil, nil, body_613421)

var createQueryLoggingConfig* = Call_CreateQueryLoggingConfig_613408(
    name: "createQueryLoggingConfig", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_CreateQueryLoggingConfig_613409, base: "/",
    url: url_CreateQueryLoggingConfig_613410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueryLoggingConfigs_613392 = ref object of OpenApiRestCall_612658
proc url_ListQueryLoggingConfigs_613394(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListQueryLoggingConfigs_613393(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nexttoken: JString
  ##            : <p>(Optional) If the current AWS account has more than <code>MaxResults</code> query logging configurations, use <code>NextToken</code> to get the second and subsequent pages of results.</p> <p>For the first <code>ListQueryLoggingConfigs</code> request, omit this value.</p> <p>For the second and subsequent requests, get the value of <code>NextToken</code> from the previous response and specify that value for <code>NextToken</code> in the request.</p>
  ##   maxresults: JString
  ##             : <p>(Optional) The maximum number of query logging configurations that you want Amazon Route 53 to return in response to the current request. If the current AWS account has more than <code>MaxResults</code> configurations, use the value of <a 
  ## href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListQueryLoggingConfigs.html#API_ListQueryLoggingConfigs_RequestSyntax">NextToken</a> in the response to get the next page of results.</p> <p>If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 100 configurations.</p>
  ##   hostedzoneid: JString
  ##               : <p>(Optional) If you want to list the query logging configuration that is associated with a hosted zone, specify the ID in <code>HostedZoneId</code>. </p> <p>If you don't specify a hosted zone ID, <code>ListQueryLoggingConfigs</code> returns all of the configurations that are associated with the current AWS account.</p>
  section = newJObject()
  var valid_613395 = query.getOrDefault("nexttoken")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "nexttoken", valid_613395
  var valid_613396 = query.getOrDefault("maxresults")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "maxresults", valid_613396
  var valid_613397 = query.getOrDefault("hostedzoneid")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "hostedzoneid", valid_613397
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
  var valid_613398 = header.getOrDefault("X-Amz-Signature")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Signature", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Content-Sha256", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-Date")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Date", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Credential")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Credential", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Security-Token")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Security-Token", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Algorithm")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Algorithm", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-SignedHeaders", valid_613404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613405: Call_ListQueryLoggingConfigs_613392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_613405.validator(path, query, header, formData, body)
  let scheme = call_613405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613405.url(scheme.get, call_613405.host, call_613405.base,
                         call_613405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613405, url, valid)

proc call*(call_613406: Call_ListQueryLoggingConfigs_613392;
          nexttoken: string = ""; maxresults: string = ""; hostedzoneid: string = ""): Recallable =
  ## listQueryLoggingConfigs
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   nexttoken: string
  ##            : <p>(Optional) If the current AWS account has more than <code>MaxResults</code> query logging configurations, use <code>NextToken</code> to get the second and subsequent pages of results.</p> <p>For the first <code>ListQueryLoggingConfigs</code> request, omit this value.</p> <p>For the second and subsequent requests, get the value of <code>NextToken</code> from the previous response and specify that value for <code>NextToken</code> in the request.</p>
  ##   maxresults: string
  ##             : <p>(Optional) The maximum number of query logging configurations that you want Amazon Route 53 to return in response to the current request. If the current AWS account has more than <code>MaxResults</code> configurations, use the value of <a 
  ## href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListQueryLoggingConfigs.html#API_ListQueryLoggingConfigs_RequestSyntax">NextToken</a> in the response to get the next page of results.</p> <p>If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 100 configurations.</p>
  ##   hostedzoneid: string
  ##               : <p>(Optional) If you want to list the query logging configuration that is associated with a hosted zone, specify the ID in <code>HostedZoneId</code>. </p> <p>If you don't specify a hosted zone ID, <code>ListQueryLoggingConfigs</code> returns all of the configurations that are associated with the current AWS account.</p>
  var query_613407 = newJObject()
  add(query_613407, "nexttoken", newJString(nexttoken))
  add(query_613407, "maxresults", newJString(maxresults))
  add(query_613407, "hostedzoneid", newJString(hostedzoneid))
  result = call_613406.call(nil, query_613407, nil, nil, nil)

var listQueryLoggingConfigs* = Call_ListQueryLoggingConfigs_613392(
    name: "listQueryLoggingConfigs", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_ListQueryLoggingConfigs_613393, base: "/",
    url: url_ListQueryLoggingConfigs_613394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReusableDelegationSet_613437 = ref object of OpenApiRestCall_612658
proc url_CreateReusableDelegationSet_613439(protocol: Scheme; host: string;
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

proc validate_CreateReusableDelegationSet_613438(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
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
  var valid_613440 = header.getOrDefault("X-Amz-Signature")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Signature", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Content-Sha256", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-Date")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Date", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-Credential")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Credential", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Security-Token")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Security-Token", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Algorithm")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Algorithm", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-SignedHeaders", valid_613446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613448: Call_CreateReusableDelegationSet_613437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ## 
  let valid = call_613448.validator(path, query, header, formData, body)
  let scheme = call_613448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613448.url(scheme.get, call_613448.host, call_613448.base,
                         call_613448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613448, url, valid)

proc call*(call_613449: Call_CreateReusableDelegationSet_613437; body: JsonNode): Recallable =
  ## createReusableDelegationSet
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613450 = newJObject()
  if body != nil:
    body_613450 = body
  result = call_613449.call(nil, nil, nil, nil, body_613450)

var createReusableDelegationSet* = Call_CreateReusableDelegationSet_613437(
    name: "createReusableDelegationSet", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_CreateReusableDelegationSet_613438, base: "/",
    url: url_CreateReusableDelegationSet_613439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReusableDelegationSets_613422 = ref object of OpenApiRestCall_612658
proc url_ListReusableDelegationSets_613424(protocol: Scheme; host: string;
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

proc validate_ListReusableDelegationSets_613423(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxitems: JString
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  section = newJObject()
  var valid_613425 = query.getOrDefault("maxitems")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "maxitems", valid_613425
  var valid_613426 = query.getOrDefault("marker")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "marker", valid_613426
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
  var valid_613427 = header.getOrDefault("X-Amz-Signature")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Signature", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Content-Sha256", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Date")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Date", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Credential")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Credential", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Security-Token")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Security-Token", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Algorithm")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Algorithm", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-SignedHeaders", valid_613433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613434: Call_ListReusableDelegationSets_613422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  let valid = call_613434.validator(path, query, header, formData, body)
  let scheme = call_613434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613434.url(scheme.get, call_613434.host, call_613434.base,
                         call_613434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613434, url, valid)

proc call*(call_613435: Call_ListReusableDelegationSets_613422;
          maxitems: string = ""; marker: string = ""): Recallable =
  ## listReusableDelegationSets
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ##   maxitems: string
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  var query_613436 = newJObject()
  add(query_613436, "maxitems", newJString(maxitems))
  add(query_613436, "marker", newJString(marker))
  result = call_613435.call(nil, query_613436, nil, nil, nil)

var listReusableDelegationSets* = Call_ListReusableDelegationSets_613422(
    name: "listReusableDelegationSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_ListReusableDelegationSets_613423, base: "/",
    url: url_ListReusableDelegationSets_613424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicy_613451 = ref object of OpenApiRestCall_612658
proc url_CreateTrafficPolicy_613453(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrafficPolicy_613452(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
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
  var valid_613454 = header.getOrDefault("X-Amz-Signature")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Signature", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Content-Sha256", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-Date")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Date", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Credential")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Credential", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Security-Token")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Security-Token", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Algorithm")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Algorithm", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-SignedHeaders", valid_613460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613462: Call_CreateTrafficPolicy_613451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ## 
  let valid = call_613462.validator(path, query, header, formData, body)
  let scheme = call_613462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613462.url(scheme.get, call_613462.host, call_613462.base,
                         call_613462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613462, url, valid)

proc call*(call_613463: Call_CreateTrafficPolicy_613451; body: JsonNode): Recallable =
  ## createTrafficPolicy
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ##   body: JObject (required)
  var body_613464 = newJObject()
  if body != nil:
    body_613464 = body
  result = call_613463.call(nil, nil, nil, nil, body_613464)

var createTrafficPolicy* = Call_CreateTrafficPolicy_613451(
    name: "createTrafficPolicy", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy",
    validator: validate_CreateTrafficPolicy_613452, base: "/",
    url: url_CreateTrafficPolicy_613453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyInstance_613465 = ref object of OpenApiRestCall_612658
proc url_CreateTrafficPolicyInstance_613467(protocol: Scheme; host: string;
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

proc validate_CreateTrafficPolicyInstance_613466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
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
  var valid_613468 = header.getOrDefault("X-Amz-Signature")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Signature", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Content-Sha256", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Date")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Date", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Credential")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Credential", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Security-Token")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Security-Token", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Algorithm")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Algorithm", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-SignedHeaders", valid_613474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613476: Call_CreateTrafficPolicyInstance_613465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ## 
  let valid = call_613476.validator(path, query, header, formData, body)
  let scheme = call_613476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613476.url(scheme.get, call_613476.host, call_613476.base,
                         call_613476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613476, url, valid)

proc call*(call_613477: Call_CreateTrafficPolicyInstance_613465; body: JsonNode): Recallable =
  ## createTrafficPolicyInstance
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ##   body: JObject (required)
  var body_613478 = newJObject()
  if body != nil:
    body_613478 = body
  result = call_613477.call(nil, nil, nil, nil, body_613478)

var createTrafficPolicyInstance* = Call_CreateTrafficPolicyInstance_613465(
    name: "createTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstance",
    validator: validate_CreateTrafficPolicyInstance_613466, base: "/",
    url: url_CreateTrafficPolicyInstance_613467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyVersion_613479 = ref object of OpenApiRestCall_612658
proc url_CreateTrafficPolicyVersion_613481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTrafficPolicyVersion_613480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy for which you want to create a new version.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613482 = path.getOrDefault("Id")
  valid_613482 = validateParameter(valid_613482, JString, required = true,
                                 default = nil)
  if valid_613482 != nil:
    section.add "Id", valid_613482
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
  var valid_613483 = header.getOrDefault("X-Amz-Signature")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Signature", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Content-Sha256", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Date")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Date", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Credential")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Credential", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Security-Token")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Security-Token", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Algorithm")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Algorithm", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-SignedHeaders", valid_613489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613491: Call_CreateTrafficPolicyVersion_613479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ## 
  let valid = call_613491.validator(path, query, header, formData, body)
  let scheme = call_613491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613491.url(scheme.get, call_613491.host, call_613491.base,
                         call_613491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613491, url, valid)

proc call*(call_613492: Call_CreateTrafficPolicyVersion_613479; body: JsonNode;
          Id: string): Recallable =
  ## createTrafficPolicyVersion
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the traffic policy for which you want to create a new version.
  var path_613493 = newJObject()
  var body_613494 = newJObject()
  if body != nil:
    body_613494 = body
  add(path_613493, "Id", newJString(Id))
  result = call_613492.call(path_613493, nil, nil, nil, body_613494)

var createTrafficPolicyVersion* = Call_CreateTrafficPolicyVersion_613479(
    name: "createTrafficPolicyVersion", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy/{Id}",
    validator: validate_CreateTrafficPolicyVersion_613480, base: "/",
    url: url_CreateTrafficPolicyVersion_613481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCAssociationAuthorization_613512 = ref object of OpenApiRestCall_612658
proc url_CreateVPCAssociationAuthorization_613514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/authorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVPCAssociationAuthorization_613513(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the private hosted zone that you want to authorize associating a VPC with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613515 = path.getOrDefault("Id")
  valid_613515 = validateParameter(valid_613515, JString, required = true,
                                 default = nil)
  if valid_613515 != nil:
    section.add "Id", valid_613515
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
  var valid_613516 = header.getOrDefault("X-Amz-Signature")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Signature", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Content-Sha256", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Date")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Date", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Credential")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Credential", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Security-Token")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Security-Token", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Algorithm")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Algorithm", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-SignedHeaders", valid_613522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613524: Call_CreateVPCAssociationAuthorization_613512;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ## 
  let valid = call_613524.validator(path, query, header, formData, body)
  let scheme = call_613524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613524.url(scheme.get, call_613524.host, call_613524.base,
                         call_613524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613524, url, valid)

proc call*(call_613525: Call_CreateVPCAssociationAuthorization_613512;
          body: JsonNode; Id: string): Recallable =
  ## createVPCAssociationAuthorization
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to authorize associating a VPC with.
  var path_613526 = newJObject()
  var body_613527 = newJObject()
  if body != nil:
    body_613527 = body
  add(path_613526, "Id", newJString(Id))
  result = call_613525.call(path_613526, nil, nil, nil, body_613527)

var createVPCAssociationAuthorization* = Call_CreateVPCAssociationAuthorization_613512(
    name: "createVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_CreateVPCAssociationAuthorization_613513, base: "/",
    url: url_CreateVPCAssociationAuthorization_613514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCAssociationAuthorizations_613495 = ref object of OpenApiRestCall_612658
proc url_ListVPCAssociationAuthorizations_613497(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/authorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVPCAssociationAuthorizations_613496(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone for which you want a list of VPCs that can be associated with the hosted zone.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613498 = path.getOrDefault("Id")
  valid_613498 = validateParameter(valid_613498, JString, required = true,
                                 default = nil)
  if valid_613498 != nil:
    section.add "Id", valid_613498
  result.add "path", section
  ## parameters in `query` object:
  ##   nexttoken: JString
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   maxresults: JString
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  section = newJObject()
  var valid_613499 = query.getOrDefault("nexttoken")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "nexttoken", valid_613499
  var valid_613500 = query.getOrDefault("maxresults")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "maxresults", valid_613500
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

proc call*(call_613508: Call_ListVPCAssociationAuthorizations_613495;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ## 
  let valid = call_613508.validator(path, query, header, formData, body)
  let scheme = call_613508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613508.url(scheme.get, call_613508.host, call_613508.base,
                         call_613508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613508, url, valid)

proc call*(call_613509: Call_ListVPCAssociationAuthorizations_613495; Id: string;
          nexttoken: string = ""; maxresults: string = ""): Recallable =
  ## listVPCAssociationAuthorizations
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ##   nexttoken: string
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   maxresults: string
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  ##   Id: string (required)
  ##     : The ID of the hosted zone for which you want a list of VPCs that can be associated with the hosted zone.
  var path_613510 = newJObject()
  var query_613511 = newJObject()
  add(query_613511, "nexttoken", newJString(nexttoken))
  add(query_613511, "maxresults", newJString(maxresults))
  add(path_613510, "Id", newJString(Id))
  result = call_613509.call(path_613510, query_613511, nil, nil, nil)

var listVPCAssociationAuthorizations* = Call_ListVPCAssociationAuthorizations_613495(
    name: "listVPCAssociationAuthorizations", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_ListVPCAssociationAuthorizations_613496, base: "/",
    url: url_ListVPCAssociationAuthorizations_613497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHealthCheck_613542 = ref object of OpenApiRestCall_612658
proc url_UpdateHealthCheck_613544(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateHealthCheck_613543(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The ID for the health check for which you want detailed information. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_613545 = path.getOrDefault("HealthCheckId")
  valid_613545 = validateParameter(valid_613545, JString, required = true,
                                 default = nil)
  if valid_613545 != nil:
    section.add "HealthCheckId", valid_613545
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
  var valid_613546 = header.getOrDefault("X-Amz-Signature")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Signature", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Content-Sha256", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Date")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Date", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Credential")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Credential", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Security-Token")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Security-Token", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Algorithm")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Algorithm", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-SignedHeaders", valid_613552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613554: Call_UpdateHealthCheck_613542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_613554.validator(path, query, header, formData, body)
  let scheme = call_613554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613554.url(scheme.get, call_613554.host, call_613554.base,
                         call_613554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613554, url, valid)

proc call*(call_613555: Call_UpdateHealthCheck_613542; HealthCheckId: string;
          body: JsonNode): Recallable =
  ## updateHealthCheck
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   HealthCheckId: string (required)
  ##                : The ID for the health check for which you want detailed information. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.
  ##   body: JObject (required)
  var path_613556 = newJObject()
  var body_613557 = newJObject()
  add(path_613556, "HealthCheckId", newJString(HealthCheckId))
  if body != nil:
    body_613557 = body
  result = call_613555.call(path_613556, nil, nil, nil, body_613557)

var updateHealthCheck* = Call_UpdateHealthCheck_613542(name: "updateHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_UpdateHealthCheck_613543, base: "/",
    url: url_UpdateHealthCheck_613544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheck_613528 = ref object of OpenApiRestCall_612658
proc url_GetHealthCheck_613530(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHealthCheck_613529(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about a specified health check.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The identifier that Amazon Route 53 assigned to the health check when you created it. When you add or update a resource record set, you use this value to specify which health check to use. The value can be up to 64 characters long.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_613531 = path.getOrDefault("HealthCheckId")
  valid_613531 = validateParameter(valid_613531, JString, required = true,
                                 default = nil)
  if valid_613531 != nil:
    section.add "HealthCheckId", valid_613531
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
  var valid_613532 = header.getOrDefault("X-Amz-Signature")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Signature", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Content-Sha256", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Date")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Date", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Credential")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Credential", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Security-Token")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Security-Token", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Algorithm")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Algorithm", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-SignedHeaders", valid_613538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613539: Call_GetHealthCheck_613528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified health check.
  ## 
  let valid = call_613539.validator(path, query, header, formData, body)
  let scheme = call_613539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613539.url(scheme.get, call_613539.host, call_613539.base,
                         call_613539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613539, url, valid)

proc call*(call_613540: Call_GetHealthCheck_613528; HealthCheckId: string): Recallable =
  ## getHealthCheck
  ## Gets information about a specified health check.
  ##   HealthCheckId: string (required)
  ##                : The identifier that Amazon Route 53 assigned to the health check when you created it. When you add or update a resource record set, you use this value to specify which health check to use. The value can be up to 64 characters long.
  var path_613541 = newJObject()
  add(path_613541, "HealthCheckId", newJString(HealthCheckId))
  result = call_613540.call(path_613541, nil, nil, nil, nil)

var getHealthCheck* = Call_GetHealthCheck_613528(name: "getHealthCheck",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_GetHealthCheck_613529, base: "/", url: url_GetHealthCheck_613530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHealthCheck_613558 = ref object of OpenApiRestCall_612658
proc url_DeleteHealthCheck_613560(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteHealthCheck_613559(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The ID of the health check that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_613561 = path.getOrDefault("HealthCheckId")
  valid_613561 = validateParameter(valid_613561, JString, required = true,
                                 default = nil)
  if valid_613561 != nil:
    section.add "HealthCheckId", valid_613561
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
  var valid_613562 = header.getOrDefault("X-Amz-Signature")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Signature", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Content-Sha256", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Date")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Date", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Credential")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Credential", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Security-Token")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Security-Token", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Algorithm")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Algorithm", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-SignedHeaders", valid_613568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613569: Call_DeleteHealthCheck_613558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_613569.validator(path, query, header, formData, body)
  let scheme = call_613569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613569.url(scheme.get, call_613569.host, call_613569.base,
                         call_613569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613569, url, valid)

proc call*(call_613570: Call_DeleteHealthCheck_613558; HealthCheckId: string): Recallable =
  ## deleteHealthCheck
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ##   HealthCheckId: string (required)
  ##                : The ID of the health check that you want to delete.
  var path_613571 = newJObject()
  add(path_613571, "HealthCheckId", newJString(HealthCheckId))
  result = call_613570.call(path_613571, nil, nil, nil, nil)

var deleteHealthCheck* = Call_DeleteHealthCheck_613558(name: "deleteHealthCheck",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_DeleteHealthCheck_613559, base: "/",
    url: url_DeleteHealthCheck_613560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHostedZoneComment_613586 = ref object of OpenApiRestCall_612658
proc url_UpdateHostedZoneComment_613588(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateHostedZoneComment_613587(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the comment for a specified hosted zone.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID for the hosted zone that you want to update the comment for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613589 = path.getOrDefault("Id")
  valid_613589 = validateParameter(valid_613589, JString, required = true,
                                 default = nil)
  if valid_613589 != nil:
    section.add "Id", valid_613589
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
  var valid_613590 = header.getOrDefault("X-Amz-Signature")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Signature", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Content-Sha256", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Date")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Date", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Credential")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Credential", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Security-Token")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Security-Token", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Algorithm")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Algorithm", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-SignedHeaders", valid_613596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613598: Call_UpdateHostedZoneComment_613586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified hosted zone.
  ## 
  let valid = call_613598.validator(path, query, header, formData, body)
  let scheme = call_613598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613598.url(scheme.get, call_613598.host, call_613598.base,
                         call_613598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613598, url, valid)

proc call*(call_613599: Call_UpdateHostedZoneComment_613586; body: JsonNode;
          Id: string): Recallable =
  ## updateHostedZoneComment
  ## Updates the comment for a specified hosted zone.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID for the hosted zone that you want to update the comment for.
  var path_613600 = newJObject()
  var body_613601 = newJObject()
  if body != nil:
    body_613601 = body
  add(path_613600, "Id", newJString(Id))
  result = call_613599.call(path_613600, nil, nil, nil, body_613601)

var updateHostedZoneComment* = Call_UpdateHostedZoneComment_613586(
    name: "updateHostedZoneComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}",
    validator: validate_UpdateHostedZoneComment_613587, base: "/",
    url: url_UpdateHostedZoneComment_613588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZone_613572 = ref object of OpenApiRestCall_612658
proc url_GetHostedZone_613574(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHostedZone_613573(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613575 = path.getOrDefault("Id")
  valid_613575 = validateParameter(valid_613575, JString, required = true,
                                 default = nil)
  if valid_613575 != nil:
    section.add "Id", valid_613575
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
  var valid_613576 = header.getOrDefault("X-Amz-Signature")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Signature", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Content-Sha256", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Date")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Date", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Credential")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Credential", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Security-Token")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Security-Token", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Algorithm")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Algorithm", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-SignedHeaders", valid_613582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613583: Call_GetHostedZone_613572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ## 
  let valid = call_613583.validator(path, query, header, formData, body)
  let scheme = call_613583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613583.url(scheme.get, call_613583.host, call_613583.base,
                         call_613583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613583, url, valid)

proc call*(call_613584: Call_GetHostedZone_613572; Id: string): Recallable =
  ## getHostedZone
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get information about.
  var path_613585 = newJObject()
  add(path_613585, "Id", newJString(Id))
  result = call_613584.call(path_613585, nil, nil, nil, nil)

var getHostedZone* = Call_GetHostedZone_613572(name: "getHostedZone",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_GetHostedZone_613573,
    base: "/", url: url_GetHostedZone_613574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHostedZone_613602 = ref object of OpenApiRestCall_612658
proc url_DeleteHostedZone_613604(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteHostedZone_613603(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613605 = path.getOrDefault("Id")
  valid_613605 = validateParameter(valid_613605, JString, required = true,
                                 default = nil)
  if valid_613605 != nil:
    section.add "Id", valid_613605
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
  var valid_613606 = header.getOrDefault("X-Amz-Signature")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Signature", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Content-Sha256", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Date")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Date", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Credential")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Credential", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Security-Token")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Security-Token", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Algorithm")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Algorithm", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-SignedHeaders", valid_613612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613613: Call_DeleteHostedZone_613602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ## 
  let valid = call_613613.validator(path, query, header, formData, body)
  let scheme = call_613613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613613.url(scheme.get, call_613613.host, call_613613.base,
                         call_613613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613613, url, valid)

proc call*(call_613614: Call_DeleteHostedZone_613602; Id: string): Recallable =
  ## deleteHostedZone
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the hosted zone you want to delete.
  var path_613615 = newJObject()
  add(path_613615, "Id", newJString(Id))
  result = call_613614.call(path_613615, nil, nil, nil, nil)

var deleteHostedZone* = Call_DeleteHostedZone_613602(name: "deleteHostedZone",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_DeleteHostedZone_613603,
    base: "/", url: url_DeleteHostedZone_613604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryLoggingConfig_613616 = ref object of OpenApiRestCall_612658
proc url_GetQueryLoggingConfig_613618(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/queryloggingconfig/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetQueryLoggingConfig_613617(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration for DNS query logging that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613619 = path.getOrDefault("Id")
  valid_613619 = validateParameter(valid_613619, JString, required = true,
                                 default = nil)
  if valid_613619 != nil:
    section.add "Id", valid_613619
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
  var valid_613620 = header.getOrDefault("X-Amz-Signature")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Signature", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Content-Sha256", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Date")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Date", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Credential")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Credential", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Security-Token")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Security-Token", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Algorithm")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Algorithm", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-SignedHeaders", valid_613626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613627: Call_GetQueryLoggingConfig_613616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ## 
  let valid = call_613627.validator(path, query, header, formData, body)
  let scheme = call_613627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613627.url(scheme.get, call_613627.host, call_613627.base,
                         call_613627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613627, url, valid)

proc call*(call_613628: Call_GetQueryLoggingConfig_613616; Id: string): Recallable =
  ## getQueryLoggingConfig
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration for DNS query logging that you want to get information about.
  var path_613629 = newJObject()
  add(path_613629, "Id", newJString(Id))
  result = call_613628.call(path_613629, nil, nil, nil, nil)

var getQueryLoggingConfig* = Call_GetQueryLoggingConfig_613616(
    name: "getQueryLoggingConfig", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_GetQueryLoggingConfig_613617, base: "/",
    url: url_GetQueryLoggingConfig_613618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueryLoggingConfig_613630 = ref object of OpenApiRestCall_612658
proc url_DeleteQueryLoggingConfig_613632(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/queryloggingconfig/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteQueryLoggingConfig_613631(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration that you want to delete. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613633 = path.getOrDefault("Id")
  valid_613633 = validateParameter(valid_613633, JString, required = true,
                                 default = nil)
  if valid_613633 != nil:
    section.add "Id", valid_613633
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
  var valid_613634 = header.getOrDefault("X-Amz-Signature")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Signature", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Content-Sha256", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Date")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Date", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Credential")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Credential", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Security-Token")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Security-Token", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Algorithm")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Algorithm", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-SignedHeaders", valid_613640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613641: Call_DeleteQueryLoggingConfig_613630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ## 
  let valid = call_613641.validator(path, query, header, formData, body)
  let scheme = call_613641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613641.url(scheme.get, call_613641.host, call_613641.base,
                         call_613641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613641, url, valid)

proc call*(call_613642: Call_DeleteQueryLoggingConfig_613630; Id: string): Recallable =
  ## deleteQueryLoggingConfig
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration that you want to delete. 
  var path_613643 = newJObject()
  add(path_613643, "Id", newJString(Id))
  result = call_613642.call(path_613643, nil, nil, nil, nil)

var deleteQueryLoggingConfig* = Call_DeleteQueryLoggingConfig_613630(
    name: "deleteQueryLoggingConfig", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_DeleteQueryLoggingConfig_613631, base: "/",
    url: url_DeleteQueryLoggingConfig_613632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSet_613644 = ref object of OpenApiRestCall_612658
proc url_GetReusableDelegationSet_613646(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/delegationset/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetReusableDelegationSet_613645(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the reusable delegation set that you want to get a list of name servers for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613647 = path.getOrDefault("Id")
  valid_613647 = validateParameter(valid_613647, JString, required = true,
                                 default = nil)
  if valid_613647 != nil:
    section.add "Id", valid_613647
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
  var valid_613648 = header.getOrDefault("X-Amz-Signature")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Signature", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Content-Sha256", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Date")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Date", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Credential")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Credential", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Security-Token")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Security-Token", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Algorithm")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Algorithm", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-SignedHeaders", valid_613654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613655: Call_GetReusableDelegationSet_613644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ## 
  let valid = call_613655.validator(path, query, header, formData, body)
  let scheme = call_613655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613655.url(scheme.get, call_613655.host, call_613655.base,
                         call_613655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613655, url, valid)

proc call*(call_613656: Call_GetReusableDelegationSet_613644; Id: string): Recallable =
  ## getReusableDelegationSet
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to get a list of name servers for.
  var path_613657 = newJObject()
  add(path_613657, "Id", newJString(Id))
  result = call_613656.call(path_613657, nil, nil, nil, nil)

var getReusableDelegationSet* = Call_GetReusableDelegationSet_613644(
    name: "getReusableDelegationSet", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_GetReusableDelegationSet_613645, base: "/",
    url: url_GetReusableDelegationSet_613646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReusableDelegationSet_613658 = ref object of OpenApiRestCall_612658
proc url_DeleteReusableDelegationSet_613660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/delegationset/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteReusableDelegationSet_613659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the reusable delegation set that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613661 = path.getOrDefault("Id")
  valid_613661 = validateParameter(valid_613661, JString, required = true,
                                 default = nil)
  if valid_613661 != nil:
    section.add "Id", valid_613661
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
  var valid_613662 = header.getOrDefault("X-Amz-Signature")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Signature", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Content-Sha256", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Date")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Date", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Credential")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Credential", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Security-Token")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Security-Token", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Algorithm")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Algorithm", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-SignedHeaders", valid_613668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613669: Call_DeleteReusableDelegationSet_613658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ## 
  let valid = call_613669.validator(path, query, header, formData, body)
  let scheme = call_613669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613669.url(scheme.get, call_613669.host, call_613669.base,
                         call_613669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613669, url, valid)

proc call*(call_613670: Call_DeleteReusableDelegationSet_613658; Id: string): Recallable =
  ## deleteReusableDelegationSet
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to delete.
  var path_613671 = newJObject()
  add(path_613671, "Id", newJString(Id))
  result = call_613670.call(path_613671, nil, nil, nil, nil)

var deleteReusableDelegationSet* = Call_DeleteReusableDelegationSet_613658(
    name: "deleteReusableDelegationSet", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_DeleteReusableDelegationSet_613659, base: "/",
    url: url_DeleteReusableDelegationSet_613660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyComment_613687 = ref object of OpenApiRestCall_612658
proc url_UpdateTrafficPolicyComment_613689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTrafficPolicyComment_613688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the comment for a specified traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Version: JInt (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  ##   Id: JString (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Version` field"
  var valid_613690 = path.getOrDefault("Version")
  valid_613690 = validateParameter(valid_613690, JInt, required = true, default = nil)
  if valid_613690 != nil:
    section.add "Version", valid_613690
  var valid_613691 = path.getOrDefault("Id")
  valid_613691 = validateParameter(valid_613691, JString, required = true,
                                 default = nil)
  if valid_613691 != nil:
    section.add "Id", valid_613691
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

proc call*(call_613700: Call_UpdateTrafficPolicyComment_613687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified traffic policy version.
  ## 
  let valid = call_613700.validator(path, query, header, formData, body)
  let scheme = call_613700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613700.url(scheme.get, call_613700.host, call_613700.base,
                         call_613700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613700, url, valid)

proc call*(call_613701: Call_UpdateTrafficPolicyComment_613687; Version: int;
          body: JsonNode; Id: string): Recallable =
  ## updateTrafficPolicyComment
  ## Updates the comment for a specified traffic policy version.
  ##   Version: int (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  var path_613702 = newJObject()
  var body_613703 = newJObject()
  add(path_613702, "Version", newJInt(Version))
  if body != nil:
    body_613703 = body
  add(path_613702, "Id", newJString(Id))
  result = call_613701.call(path_613702, nil, nil, nil, body_613703)

var updateTrafficPolicyComment* = Call_UpdateTrafficPolicyComment_613687(
    name: "updateTrafficPolicyComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_UpdateTrafficPolicyComment_613688, base: "/",
    url: url_UpdateTrafficPolicyComment_613689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicy_613672 = ref object of OpenApiRestCall_612658
proc url_GetTrafficPolicy_613674(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTrafficPolicy_613673(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about a specific traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to get information about.
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Version` field"
  var valid_613675 = path.getOrDefault("Version")
  valid_613675 = validateParameter(valid_613675, JInt, required = true, default = nil)
  if valid_613675 != nil:
    section.add "Version", valid_613675
  var valid_613676 = path.getOrDefault("Id")
  valid_613676 = validateParameter(valid_613676, JString, required = true,
                                 default = nil)
  if valid_613676 != nil:
    section.add "Id", valid_613676
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
  if body != nil:
    result.add "body", body

proc call*(call_613684: Call_GetTrafficPolicy_613672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific traffic policy version.
  ## 
  let valid = call_613684.validator(path, query, header, formData, body)
  let scheme = call_613684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613684.url(scheme.get, call_613684.host, call_613684.base,
                         call_613684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613684, url, valid)

proc call*(call_613685: Call_GetTrafficPolicy_613672; Version: int; Id: string): Recallable =
  ## getTrafficPolicy
  ## Gets information about a specific traffic policy version.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to get information about.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to get information about.
  var path_613686 = newJObject()
  add(path_613686, "Version", newJInt(Version))
  add(path_613686, "Id", newJString(Id))
  result = call_613685.call(path_613686, nil, nil, nil, nil)

var getTrafficPolicy* = Call_GetTrafficPolicy_613672(name: "getTrafficPolicy",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_GetTrafficPolicy_613673, base: "/",
    url: url_GetTrafficPolicy_613674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicy_613704 = ref object of OpenApiRestCall_612658
proc url_DeleteTrafficPolicy_613706(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTrafficPolicy_613705(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a traffic policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to delete.
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Version` field"
  var valid_613707 = path.getOrDefault("Version")
  valid_613707 = validateParameter(valid_613707, JInt, required = true, default = nil)
  if valid_613707 != nil:
    section.add "Version", valid_613707
  var valid_613708 = path.getOrDefault("Id")
  valid_613708 = validateParameter(valid_613708, JString, required = true,
                                 default = nil)
  if valid_613708 != nil:
    section.add "Id", valid_613708
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
  var valid_613709 = header.getOrDefault("X-Amz-Signature")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Signature", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Content-Sha256", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Date")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Date", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Credential")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Credential", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Security-Token")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Security-Token", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Algorithm")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Algorithm", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-SignedHeaders", valid_613715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613716: Call_DeleteTrafficPolicy_613704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a traffic policy.
  ## 
  let valid = call_613716.validator(path, query, header, formData, body)
  let scheme = call_613716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613716.url(scheme.get, call_613716.host, call_613716.base,
                         call_613716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613716, url, valid)

proc call*(call_613717: Call_DeleteTrafficPolicy_613704; Version: int; Id: string): Recallable =
  ## deleteTrafficPolicy
  ## Deletes a traffic policy.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to delete.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to delete.
  var path_613718 = newJObject()
  add(path_613718, "Version", newJInt(Version))
  add(path_613718, "Id", newJString(Id))
  result = call_613717.call(path_613718, nil, nil, nil, nil)

var deleteTrafficPolicy* = Call_DeleteTrafficPolicy_613704(
    name: "deleteTrafficPolicy", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_DeleteTrafficPolicy_613705, base: "/",
    url: url_DeleteTrafficPolicy_613706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyInstance_613733 = ref object of OpenApiRestCall_612658
proc url_UpdateTrafficPolicyInstance_613735(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTrafficPolicyInstance_613734(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy instance that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613736 = path.getOrDefault("Id")
  valid_613736 = validateParameter(valid_613736, JString, required = true,
                                 default = nil)
  if valid_613736 != nil:
    section.add "Id", valid_613736
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
  var valid_613737 = header.getOrDefault("X-Amz-Signature")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Signature", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Content-Sha256", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Date")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Date", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Credential")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Credential", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Security-Token")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Security-Token", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Algorithm")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Algorithm", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-SignedHeaders", valid_613743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613745: Call_UpdateTrafficPolicyInstance_613733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ## 
  let valid = call_613745.validator(path, query, header, formData, body)
  let scheme = call_613745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613745.url(scheme.get, call_613745.host, call_613745.base,
                         call_613745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613745, url, valid)

proc call*(call_613746: Call_UpdateTrafficPolicyInstance_613733; body: JsonNode;
          Id: string): Recallable =
  ## updateTrafficPolicyInstance
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to update.
  var path_613747 = newJObject()
  var body_613748 = newJObject()
  if body != nil:
    body_613748 = body
  add(path_613747, "Id", newJString(Id))
  result = call_613746.call(path_613747, nil, nil, nil, body_613748)

var updateTrafficPolicyInstance* = Call_UpdateTrafficPolicyInstance_613733(
    name: "updateTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_UpdateTrafficPolicyInstance_613734, base: "/",
    url: url_UpdateTrafficPolicyInstance_613735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstance_613719 = ref object of OpenApiRestCall_612658
proc url_GetTrafficPolicyInstance_613721(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTrafficPolicyInstance_613720(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy instance that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613722 = path.getOrDefault("Id")
  valid_613722 = validateParameter(valid_613722, JString, required = true,
                                 default = nil)
  if valid_613722 != nil:
    section.add "Id", valid_613722
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
  var valid_613723 = header.getOrDefault("X-Amz-Signature")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Signature", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Content-Sha256", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Date")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Date", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Credential")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Credential", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Security-Token")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Security-Token", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Algorithm")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Algorithm", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-SignedHeaders", valid_613729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613730: Call_GetTrafficPolicyInstance_613719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_613730.validator(path, query, header, formData, body)
  let scheme = call_613730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613730.url(scheme.get, call_613730.host, call_613730.base,
                         call_613730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613730, url, valid)

proc call*(call_613731: Call_GetTrafficPolicyInstance_613719; Id: string): Recallable =
  ## getTrafficPolicyInstance
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to get information about.
  var path_613732 = newJObject()
  add(path_613732, "Id", newJString(Id))
  result = call_613731.call(path_613732, nil, nil, nil, nil)

var getTrafficPolicyInstance* = Call_GetTrafficPolicyInstance_613719(
    name: "getTrafficPolicyInstance", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_GetTrafficPolicyInstance_613720, base: "/",
    url: url_GetTrafficPolicyInstance_613721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicyInstance_613749 = ref object of OpenApiRestCall_612658
proc url_DeleteTrafficPolicyInstance_613751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTrafficPolicyInstance_613750(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : <p>The ID of the traffic policy instance that you want to delete. </p> <important> <p>When you delete a traffic policy instance, Amazon Route 53 also deletes all of the resource record sets that were created when you created the traffic policy instance.</p> </important>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613752 = path.getOrDefault("Id")
  valid_613752 = validateParameter(valid_613752, JString, required = true,
                                 default = nil)
  if valid_613752 != nil:
    section.add "Id", valid_613752
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
  var valid_613753 = header.getOrDefault("X-Amz-Signature")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Signature", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Content-Sha256", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-Date")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Date", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Credential")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Credential", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Security-Token")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Security-Token", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Algorithm")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Algorithm", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-SignedHeaders", valid_613759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613760: Call_DeleteTrafficPolicyInstance_613749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_613760.validator(path, query, header, formData, body)
  let scheme = call_613760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613760.url(scheme.get, call_613760.host, call_613760.base,
                         call_613760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613760, url, valid)

proc call*(call_613761: Call_DeleteTrafficPolicyInstance_613749; Id: string): Recallable =
  ## deleteTrafficPolicyInstance
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : <p>The ID of the traffic policy instance that you want to delete. </p> <important> <p>When you delete a traffic policy instance, Amazon Route 53 also deletes all of the resource record sets that were created when you created the traffic policy instance.</p> </important>
  var path_613762 = newJObject()
  add(path_613762, "Id", newJString(Id))
  result = call_613761.call(path_613762, nil, nil, nil, nil)

var deleteTrafficPolicyInstance* = Call_DeleteTrafficPolicyInstance_613749(
    name: "deleteTrafficPolicyInstance", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_DeleteTrafficPolicyInstance_613750, base: "/",
    url: url_DeleteTrafficPolicyInstance_613751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCAssociationAuthorization_613763 = ref object of OpenApiRestCall_612658
proc url_DeleteVPCAssociationAuthorization_613765(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/deauthorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVPCAssociationAuthorization_613764(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : When removing authorization to associate a VPC that was created by one AWS account with a hosted zone that was created with a different AWS account, the ID of the hosted zone.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613766 = path.getOrDefault("Id")
  valid_613766 = validateParameter(valid_613766, JString, required = true,
                                 default = nil)
  if valid_613766 != nil:
    section.add "Id", valid_613766
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
  var valid_613767 = header.getOrDefault("X-Amz-Signature")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Signature", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Content-Sha256", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Date")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Date", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-Credential")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Credential", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Security-Token")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Security-Token", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Algorithm")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Algorithm", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-SignedHeaders", valid_613773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613775: Call_DeleteVPCAssociationAuthorization_613763;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ## 
  let valid = call_613775.validator(path, query, header, formData, body)
  let scheme = call_613775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613775.url(scheme.get, call_613775.host, call_613775.base,
                         call_613775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613775, url, valid)

proc call*(call_613776: Call_DeleteVPCAssociationAuthorization_613763;
          body: JsonNode; Id: string): Recallable =
  ## deleteVPCAssociationAuthorization
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : When removing authorization to associate a VPC that was created by one AWS account with a hosted zone that was created with a different AWS account, the ID of the hosted zone.
  var path_613777 = newJObject()
  var body_613778 = newJObject()
  if body != nil:
    body_613778 = body
  add(path_613777, "Id", newJString(Id))
  result = call_613776.call(path_613777, nil, nil, nil, body_613778)

var deleteVPCAssociationAuthorization* = Call_DeleteVPCAssociationAuthorization_613763(
    name: "deleteVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/deauthorizevpcassociation",
    validator: validate_DeleteVPCAssociationAuthorization_613764, base: "/",
    url: url_DeleteVPCAssociationAuthorization_613765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateVPCFromHostedZone_613779 = ref object of OpenApiRestCall_612658
proc url_DisassociateVPCFromHostedZone_613781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/disassociatevpc")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateVPCFromHostedZone_613780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the private hosted zone that you want to disassociate a VPC from.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613782 = path.getOrDefault("Id")
  valid_613782 = validateParameter(valid_613782, JString, required = true,
                                 default = nil)
  if valid_613782 != nil:
    section.add "Id", valid_613782
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
  var valid_613783 = header.getOrDefault("X-Amz-Signature")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Signature", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Content-Sha256", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Date")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Date", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-Credential")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Credential", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-Security-Token")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Security-Token", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Algorithm")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Algorithm", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-SignedHeaders", valid_613789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613791: Call_DisassociateVPCFromHostedZone_613779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ## 
  let valid = call_613791.validator(path, query, header, formData, body)
  let scheme = call_613791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613791.url(scheme.get, call_613791.host, call_613791.base,
                         call_613791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613791, url, valid)

proc call*(call_613792: Call_DisassociateVPCFromHostedZone_613779; body: JsonNode;
          Id: string): Recallable =
  ## disassociateVPCFromHostedZone
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to disassociate a VPC from.
  var path_613793 = newJObject()
  var body_613794 = newJObject()
  if body != nil:
    body_613794 = body
  add(path_613793, "Id", newJString(Id))
  result = call_613792.call(path_613793, nil, nil, nil, body_613794)

var disassociateVPCFromHostedZone* = Call_DisassociateVPCFromHostedZone_613779(
    name: "disassociateVPCFromHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/disassociatevpc",
    validator: validate_DisassociateVPCFromHostedZone_613780, base: "/",
    url: url_DisassociateVPCFromHostedZone_613781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountLimit_613795 = ref object of OpenApiRestCall_612658
proc url_GetAccountLimit_613797(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/accountlimit/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccountLimit_613796(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_HEALTH_CHECKS_BY_OWNER</b>: The maximum number of health checks that you can create using the current account.</p> </li> <li> <p> <b>MAX_HOSTED_ZONES_BY_OWNER</b>: The maximum number of hosted zones that you can create using the current account.</p> </li> <li> <p> <b>MAX_REUSABLE_DELEGATION_SETS_BY_OWNER</b>: The maximum number of reusable delegation sets that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICIES_BY_OWNER</b>: The maximum number of traffic policies that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICY_INSTANCES_BY_OWNER</b>: The maximum number of traffic policy instances that you can create using the current account. (Traffic policy instances are referred to as traffic flow policy records in the Amazon Route 53 console.)</p> </li> </ul>
  section = newJObject()
  var valid_613798 = path.getOrDefault("Type")
  valid_613798 = validateParameter(valid_613798, JString, required = true, default = newJString(
      "MAX_HEALTH_CHECKS_BY_OWNER"))
  if valid_613798 != nil:
    section.add "Type", valid_613798
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
  var valid_613799 = header.getOrDefault("X-Amz-Signature")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Signature", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Content-Sha256", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Date")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Date", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Credential")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Credential", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Security-Token")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Security-Token", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-Algorithm")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Algorithm", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-SignedHeaders", valid_613805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613806: Call_GetAccountLimit_613795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ## 
  let valid = call_613806.validator(path, query, header, formData, body)
  let scheme = call_613806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613806.url(scheme.get, call_613806.host, call_613806.base,
                         call_613806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613806, url, valid)

proc call*(call_613807: Call_GetAccountLimit_613795;
          Type: string = "MAX_HEALTH_CHECKS_BY_OWNER"): Recallable =
  ## getAccountLimit
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_HEALTH_CHECKS_BY_OWNER</b>: The maximum number of health checks that you can create using the current account.</p> </li> <li> <p> <b>MAX_HOSTED_ZONES_BY_OWNER</b>: The maximum number of hosted zones that you can create using the current account.</p> </li> <li> <p> <b>MAX_REUSABLE_DELEGATION_SETS_BY_OWNER</b>: The maximum number of reusable delegation sets that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICIES_BY_OWNER</b>: The maximum number of traffic policies that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICY_INSTANCES_BY_OWNER</b>: The maximum number of traffic policy instances that you can create using the current account. (Traffic policy instances are referred to as traffic flow policy records in the Amazon Route 53 console.)</p> </li> </ul>
  var path_613808 = newJObject()
  add(path_613808, "Type", newJString(Type))
  result = call_613807.call(path_613808, nil, nil, nil, nil)

var getAccountLimit* = Call_GetAccountLimit_613795(name: "getAccountLimit",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/accountlimit/{Type}", validator: validate_GetAccountLimit_613796,
    base: "/", url: url_GetAccountLimit_613797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChange_613809 = ref object of OpenApiRestCall_612658
proc url_GetChange_613811(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/change/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetChange_613810(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the change batch request. The value that you specify here is the value that <code>ChangeResourceRecordSets</code> returned in the <code>Id</code> element when you submitted the request.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613812 = path.getOrDefault("Id")
  valid_613812 = validateParameter(valid_613812, JString, required = true,
                                 default = nil)
  if valid_613812 != nil:
    section.add "Id", valid_613812
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
  var valid_613813 = header.getOrDefault("X-Amz-Signature")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Signature", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Content-Sha256", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Date")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Date", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Credential")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Credential", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Security-Token")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Security-Token", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Algorithm")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Algorithm", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-SignedHeaders", valid_613819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613820: Call_GetChange_613809; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ## 
  let valid = call_613820.validator(path, query, header, formData, body)
  let scheme = call_613820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613820.url(scheme.get, call_613820.host, call_613820.base,
                         call_613820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613820, url, valid)

proc call*(call_613821: Call_GetChange_613809; Id: string): Recallable =
  ## getChange
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the change batch request. The value that you specify here is the value that <code>ChangeResourceRecordSets</code> returned in the <code>Id</code> element when you submitted the request.
  var path_613822 = newJObject()
  add(path_613822, "Id", newJString(Id))
  result = call_613821.call(path_613822, nil, nil, nil, nil)

var getChange* = Call_GetChange_613809(name: "getChange", meth: HttpMethod.HttpGet,
                                    host: "route53.amazonaws.com",
                                    route: "/2013-04-01/change/{Id}",
                                    validator: validate_GetChange_613810,
                                    base: "/", url: url_GetChange_613811,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckerIpRanges_613823 = ref object of OpenApiRestCall_612658
proc url_GetCheckerIpRanges_613825(protocol: Scheme; host: string; base: string;
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

proc validate_GetCheckerIpRanges_613824(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
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
  var valid_613826 = header.getOrDefault("X-Amz-Signature")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Signature", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Content-Sha256", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Date")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Date", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Credential")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Credential", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Security-Token")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Security-Token", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Algorithm")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Algorithm", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-SignedHeaders", valid_613832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613833: Call_GetCheckerIpRanges_613823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_613833.validator(path, query, header, formData, body)
  let scheme = call_613833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613833.url(scheme.get, call_613833.host, call_613833.base,
                         call_613833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613833, url, valid)

proc call*(call_613834: Call_GetCheckerIpRanges_613823): Recallable =
  ## getCheckerIpRanges
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  result = call_613834.call(nil, nil, nil, nil, nil)

var getCheckerIpRanges* = Call_GetCheckerIpRanges_613823(
    name: "getCheckerIpRanges", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/checkeripranges",
    validator: validate_GetCheckerIpRanges_613824, base: "/",
    url: url_GetCheckerIpRanges_613825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGeoLocation_613835 = ref object of OpenApiRestCall_612658
proc url_GetGeoLocation_613837(protocol: Scheme; host: string; base: string;
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

proc validate_GetGeoLocation_613836(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   continentcode: JString
  ##                : <p>Amazon Route 53 supports the following continent codes:</p> <ul> <li> <p> <b>AF</b>: Africa</p> </li> <li> <p> <b>AN</b>: Antarctica</p> </li> <li> <p> <b>AS</b>: Asia</p> </li> <li> <p> <b>EU</b>: Europe</p> </li> <li> <p> <b>OC</b>: Oceania</p> </li> <li> <p> <b>NA</b>: North America</p> </li> <li> <p> <b>SA</b>: South America</p> </li> </ul>
  ##   countrycode: JString
  ##              : Amazon Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.
  ##   subdivisioncode: JString
  ##                  : Amazon Route 53 uses the one- to three-letter subdivision codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>. Route 53 doesn't support subdivision codes for all countries. If you specify <code>subdivisioncode</code>, you must also specify <code>countrycode</code>. 
  section = newJObject()
  var valid_613838 = query.getOrDefault("continentcode")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "continentcode", valid_613838
  var valid_613839 = query.getOrDefault("countrycode")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "countrycode", valid_613839
  var valid_613840 = query.getOrDefault("subdivisioncode")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "subdivisioncode", valid_613840
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
  var valid_613841 = header.getOrDefault("X-Amz-Signature")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Signature", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Content-Sha256", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Date")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Date", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Credential")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Credential", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Security-Token")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Security-Token", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Algorithm")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Algorithm", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-SignedHeaders", valid_613847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613848: Call_GetGeoLocation_613835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ## 
  let valid = call_613848.validator(path, query, header, formData, body)
  let scheme = call_613848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613848.url(scheme.get, call_613848.host, call_613848.base,
                         call_613848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613848, url, valid)

proc call*(call_613849: Call_GetGeoLocation_613835; continentcode: string = "";
          countrycode: string = ""; subdivisioncode: string = ""): Recallable =
  ## getGeoLocation
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ##   continentcode: string
  ##                : <p>Amazon Route 53 supports the following continent codes:</p> <ul> <li> <p> <b>AF</b>: Africa</p> </li> <li> <p> <b>AN</b>: Antarctica</p> </li> <li> <p> <b>AS</b>: Asia</p> </li> <li> <p> <b>EU</b>: Europe</p> </li> <li> <p> <b>OC</b>: Oceania</p> </li> <li> <p> <b>NA</b>: North America</p> </li> <li> <p> <b>SA</b>: South America</p> </li> </ul>
  ##   countrycode: string
  ##              : Amazon Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.
  ##   subdivisioncode: string
  ##                  : Amazon Route 53 uses the one- to three-letter subdivision codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>. Route 53 doesn't support subdivision codes for all countries. If you specify <code>subdivisioncode</code>, you must also specify <code>countrycode</code>. 
  var query_613850 = newJObject()
  add(query_613850, "continentcode", newJString(continentcode))
  add(query_613850, "countrycode", newJString(countrycode))
  add(query_613850, "subdivisioncode", newJString(subdivisioncode))
  result = call_613849.call(nil, query_613850, nil, nil, nil)

var getGeoLocation* = Call_GetGeoLocation_613835(name: "getGeoLocation",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocation", validator: validate_GetGeoLocation_613836,
    base: "/", url: url_GetGeoLocation_613837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckCount_613851 = ref object of OpenApiRestCall_612658
proc url_GetHealthCheckCount_613853(protocol: Scheme; host: string; base: string;
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

proc validate_GetHealthCheckCount_613852(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the number of health checks that are associated with the current AWS account.
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
  var valid_613854 = header.getOrDefault("X-Amz-Signature")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Signature", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Content-Sha256", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Date")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Date", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Credential")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Credential", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Security-Token")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Security-Token", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Algorithm")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Algorithm", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-SignedHeaders", valid_613860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613861: Call_GetHealthCheckCount_613851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of health checks that are associated with the current AWS account.
  ## 
  let valid = call_613861.validator(path, query, header, formData, body)
  let scheme = call_613861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613861.url(scheme.get, call_613861.host, call_613861.base,
                         call_613861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613861, url, valid)

proc call*(call_613862: Call_GetHealthCheckCount_613851): Recallable =
  ## getHealthCheckCount
  ## Retrieves the number of health checks that are associated with the current AWS account.
  result = call_613862.call(nil, nil, nil, nil, nil)

var getHealthCheckCount* = Call_GetHealthCheckCount_613851(
    name: "getHealthCheckCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/healthcheckcount",
    validator: validate_GetHealthCheckCount_613852, base: "/",
    url: url_GetHealthCheckCount_613853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckLastFailureReason_613863 = ref object of OpenApiRestCall_612658
proc url_GetHealthCheckLastFailureReason_613865(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId"),
               (kind: ConstantSegment, value: "/lastfailurereason")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHealthCheckLastFailureReason_613864(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the reason that a specified health check failed most recently.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : <p>The ID for the health check for which you want the last failure reason. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to get the last failure reason for a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckLastFailureReason</code> for a calculated health check.</p> </note>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_613866 = path.getOrDefault("HealthCheckId")
  valid_613866 = validateParameter(valid_613866, JString, required = true,
                                 default = nil)
  if valid_613866 != nil:
    section.add "HealthCheckId", valid_613866
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
  var valid_613867 = header.getOrDefault("X-Amz-Signature")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Signature", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Content-Sha256", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Date")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Date", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Credential")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Credential", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-Security-Token")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-Security-Token", valid_613871
  var valid_613872 = header.getOrDefault("X-Amz-Algorithm")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "X-Amz-Algorithm", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-SignedHeaders", valid_613873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613874: Call_GetHealthCheckLastFailureReason_613863;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the reason that a specified health check failed most recently.
  ## 
  let valid = call_613874.validator(path, query, header, formData, body)
  let scheme = call_613874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613874.url(scheme.get, call_613874.host, call_613874.base,
                         call_613874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613874, url, valid)

proc call*(call_613875: Call_GetHealthCheckLastFailureReason_613863;
          HealthCheckId: string): Recallable =
  ## getHealthCheckLastFailureReason
  ## Gets the reason that a specified health check failed most recently.
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check for which you want the last failure reason. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to get the last failure reason for a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckLastFailureReason</code> for a calculated health check.</p> </note>
  var path_613876 = newJObject()
  add(path_613876, "HealthCheckId", newJString(HealthCheckId))
  result = call_613875.call(path_613876, nil, nil, nil, nil)

var getHealthCheckLastFailureReason* = Call_GetHealthCheckLastFailureReason_613863(
    name: "getHealthCheckLastFailureReason", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/lastfailurereason",
    validator: validate_GetHealthCheckLastFailureReason_613864, base: "/",
    url: url_GetHealthCheckLastFailureReason_613865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckStatus_613877 = ref object of OpenApiRestCall_612658
proc url_GetHealthCheckStatus_613879(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHealthCheckStatus_613878(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets status of a specified health check. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : <p>The ID for the health check that you want the current status for. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to check the status of a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckStatus</code> to get the status of a calculated health check.</p> </note>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_613880 = path.getOrDefault("HealthCheckId")
  valid_613880 = validateParameter(valid_613880, JString, required = true,
                                 default = nil)
  if valid_613880 != nil:
    section.add "HealthCheckId", valid_613880
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
  var valid_613881 = header.getOrDefault("X-Amz-Signature")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Signature", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Content-Sha256", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Date")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Date", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Credential")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Credential", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Security-Token")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Security-Token", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Algorithm")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Algorithm", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-SignedHeaders", valid_613887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613888: Call_GetHealthCheckStatus_613877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status of a specified health check. 
  ## 
  let valid = call_613888.validator(path, query, header, formData, body)
  let scheme = call_613888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613888.url(scheme.get, call_613888.host, call_613888.base,
                         call_613888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613888, url, valid)

proc call*(call_613889: Call_GetHealthCheckStatus_613877; HealthCheckId: string): Recallable =
  ## getHealthCheckStatus
  ## Gets status of a specified health check. 
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check that you want the current status for. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to check the status of a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckStatus</code> to get the status of a calculated health check.</p> </note>
  var path_613890 = newJObject()
  add(path_613890, "HealthCheckId", newJString(HealthCheckId))
  result = call_613889.call(path_613890, nil, nil, nil, nil)

var getHealthCheckStatus* = Call_GetHealthCheckStatus_613877(
    name: "getHealthCheckStatus", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/status",
    validator: validate_GetHealthCheckStatus_613878, base: "/",
    url: url_GetHealthCheckStatus_613879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneCount_613891 = ref object of OpenApiRestCall_612658
proc url_GetHostedZoneCount_613893(protocol: Scheme; host: string; base: string;
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

proc validate_GetHostedZoneCount_613892(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
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
  var valid_613894 = header.getOrDefault("X-Amz-Signature")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Signature", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Content-Sha256", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Date")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Date", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Credential")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Credential", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Security-Token")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Security-Token", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Algorithm")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Algorithm", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-SignedHeaders", valid_613900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613901: Call_GetHostedZoneCount_613891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  ## 
  let valid = call_613901.validator(path, query, header, formData, body)
  let scheme = call_613901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613901.url(scheme.get, call_613901.host, call_613901.base,
                         call_613901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613901, url, valid)

proc call*(call_613902: Call_GetHostedZoneCount_613891): Recallable =
  ## getHostedZoneCount
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  result = call_613902.call(nil, nil, nil, nil, nil)

var getHostedZoneCount* = Call_GetHostedZoneCount_613891(
    name: "getHostedZoneCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonecount",
    validator: validate_GetHostedZoneCount_613892, base: "/",
    url: url_GetHostedZoneCount_613893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneLimit_613903 = ref object of OpenApiRestCall_612658
proc url_GetHostedZoneLimit_613905(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzonelimit/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHostedZoneLimit_613904(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  section = newJObject()
  var valid_613906 = path.getOrDefault("Type")
  valid_613906 = validateParameter(valid_613906, JString, required = true,
                                 default = newJString("MAX_RRSETS_BY_ZONE"))
  if valid_613906 != nil:
    section.add "Type", valid_613906
  var valid_613907 = path.getOrDefault("Id")
  valid_613907 = validateParameter(valid_613907, JString, required = true,
                                 default = nil)
  if valid_613907 != nil:
    section.add "Id", valid_613907
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
  var valid_613908 = header.getOrDefault("X-Amz-Signature")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Signature", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Content-Sha256", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Date")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Date", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Credential")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Credential", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Security-Token")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Security-Token", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Algorithm")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Algorithm", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-SignedHeaders", valid_613914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613915: Call_GetHostedZoneLimit_613903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_613915.validator(path, query, header, formData, body)
  let scheme = call_613915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613915.url(scheme.get, call_613915.host, call_613915.base,
                         call_613915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613915, url, valid)

proc call*(call_613916: Call_GetHostedZoneLimit_613903; Id: string;
          Type: string = "MAX_RRSETS_BY_ZONE"): Recallable =
  ## getHostedZoneLimit
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  var path_613917 = newJObject()
  add(path_613917, "Type", newJString(Type))
  add(path_613917, "Id", newJString(Id))
  result = call_613916.call(path_613917, nil, nil, nil, nil)

var getHostedZoneLimit* = Call_GetHostedZoneLimit_613903(
    name: "getHostedZoneLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzonelimit/{Id}/{Type}",
    validator: validate_GetHostedZoneLimit_613904, base: "/",
    url: url_GetHostedZoneLimit_613905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSetLimit_613918 = ref object of OpenApiRestCall_612658
proc url_GetReusableDelegationSetLimit_613920(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2013-04-01/reusabledelegationsetlimit/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetReusableDelegationSetLimit_613919(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  ##   Id: JString (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  section = newJObject()
  var valid_613921 = path.getOrDefault("Type")
  valid_613921 = validateParameter(valid_613921, JString, required = true, default = newJString(
      "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"))
  if valid_613921 != nil:
    section.add "Type", valid_613921
  var valid_613922 = path.getOrDefault("Id")
  valid_613922 = validateParameter(valid_613922, JString, required = true,
                                 default = nil)
  if valid_613922 != nil:
    section.add "Id", valid_613922
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
  var valid_613923 = header.getOrDefault("X-Amz-Signature")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-Signature", valid_613923
  var valid_613924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Content-Sha256", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Date")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Date", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Credential")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Credential", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Security-Token")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Security-Token", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Algorithm")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Algorithm", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-SignedHeaders", valid_613929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613930: Call_GetReusableDelegationSetLimit_613918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_613930.validator(path, query, header, formData, body)
  let scheme = call_613930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613930.url(scheme.get, call_613930.host, call_613930.base,
                         call_613930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613930, url, valid)

proc call*(call_613931: Call_GetReusableDelegationSetLimit_613918; Id: string;
          Type: string = "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"): Recallable =
  ## getReusableDelegationSetLimit
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Type: string (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  ##   Id: string (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  var path_613932 = newJObject()
  add(path_613932, "Type", newJString(Type))
  add(path_613932, "Id", newJString(Id))
  result = call_613931.call(path_613932, nil, nil, nil, nil)

var getReusableDelegationSetLimit* = Call_GetReusableDelegationSetLimit_613918(
    name: "getReusableDelegationSetLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/reusabledelegationsetlimit/{Id}/{Type}",
    validator: validate_GetReusableDelegationSetLimit_613919, base: "/",
    url: url_GetReusableDelegationSetLimit_613920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstanceCount_613933 = ref object of OpenApiRestCall_612658
proc url_GetTrafficPolicyInstanceCount_613935(protocol: Scheme; host: string;
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

proc validate_GetTrafficPolicyInstanceCount_613934(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
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
  var valid_613936 = header.getOrDefault("X-Amz-Signature")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Signature", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Content-Sha256", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-Date")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-Date", valid_613938
  var valid_613939 = header.getOrDefault("X-Amz-Credential")
  valid_613939 = validateParameter(valid_613939, JString, required = false,
                                 default = nil)
  if valid_613939 != nil:
    section.add "X-Amz-Credential", valid_613939
  var valid_613940 = header.getOrDefault("X-Amz-Security-Token")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "X-Amz-Security-Token", valid_613940
  var valid_613941 = header.getOrDefault("X-Amz-Algorithm")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-Algorithm", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-SignedHeaders", valid_613942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613943: Call_GetTrafficPolicyInstanceCount_613933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  ## 
  let valid = call_613943.validator(path, query, header, formData, body)
  let scheme = call_613943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613943.url(scheme.get, call_613943.host, call_613943.base,
                         call_613943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613943, url, valid)

proc call*(call_613944: Call_GetTrafficPolicyInstanceCount_613933): Recallable =
  ## getTrafficPolicyInstanceCount
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  result = call_613944.call(nil, nil, nil, nil, nil)

var getTrafficPolicyInstanceCount* = Call_GetTrafficPolicyInstanceCount_613933(
    name: "getTrafficPolicyInstanceCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstancecount",
    validator: validate_GetTrafficPolicyInstanceCount_613934, base: "/",
    url: url_GetTrafficPolicyInstanceCount_613935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGeoLocations_613945 = ref object of OpenApiRestCall_612658
proc url_ListGeoLocations_613947(protocol: Scheme; host: string; base: string;
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

proc validate_ListGeoLocations_613946(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   startcountrycode: JString
  ##                   : <p>The code for the country with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextCountryCode</code> from the previous response has a value, enter that value in <code>startcountrycode</code> to return the next page of results.</p> <p>Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.</p>
  ##   startsubdivisioncode: JString
  ##                       : <p>The code for the subdivision (for example, state or province) with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextSubdivisionCode</code> from the previous response has a value, enter that value in <code>startsubdivisioncode</code> to return the next page of results.</p> <p>To list subdivisions of a country, you must include both <code>startcountrycode</code> and <code>startsubdivisioncode</code>.</p>
  ##   startcontinentcode: JString
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  section = newJObject()
  var valid_613948 = query.getOrDefault("startcountrycode")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "startcountrycode", valid_613948
  var valid_613949 = query.getOrDefault("startsubdivisioncode")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "startsubdivisioncode", valid_613949
  var valid_613950 = query.getOrDefault("startcontinentcode")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "startcontinentcode", valid_613950
  var valid_613951 = query.getOrDefault("maxitems")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "maxitems", valid_613951
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
  var valid_613952 = header.getOrDefault("X-Amz-Signature")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Signature", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Content-Sha256", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Date")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Date", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Credential")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Credential", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-Security-Token")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-Security-Token", valid_613956
  var valid_613957 = header.getOrDefault("X-Amz-Algorithm")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Algorithm", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-SignedHeaders", valid_613958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613959: Call_ListGeoLocations_613945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ## 
  let valid = call_613959.validator(path, query, header, formData, body)
  let scheme = call_613959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613959.url(scheme.get, call_613959.host, call_613959.base,
                         call_613959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613959, url, valid)

proc call*(call_613960: Call_ListGeoLocations_613945;
          startcountrycode: string = ""; startsubdivisioncode: string = "";
          startcontinentcode: string = ""; maxitems: string = ""): Recallable =
  ## listGeoLocations
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ##   startcountrycode: string
  ##                   : <p>The code for the country with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextCountryCode</code> from the previous response has a value, enter that value in <code>startcountrycode</code> to return the next page of results.</p> <p>Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.</p>
  ##   startsubdivisioncode: string
  ##                       : <p>The code for the subdivision (for example, state or province) with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextSubdivisionCode</code> from the previous response has a value, enter that value in <code>startsubdivisioncode</code> to return the next page of results.</p> <p>To list subdivisions of a country, you must include both <code>startcountrycode</code> and <code>startsubdivisioncode</code>.</p>
  ##   startcontinentcode: string
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  var query_613961 = newJObject()
  add(query_613961, "startcountrycode", newJString(startcountrycode))
  add(query_613961, "startsubdivisioncode", newJString(startsubdivisioncode))
  add(query_613961, "startcontinentcode", newJString(startcontinentcode))
  add(query_613961, "maxitems", newJString(maxitems))
  result = call_613960.call(nil, query_613961, nil, nil, nil)

var listGeoLocations* = Call_ListGeoLocations_613945(name: "listGeoLocations",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocations", validator: validate_ListGeoLocations_613946,
    base: "/", url: url_ListGeoLocations_613947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZonesByName_613962 = ref object of OpenApiRestCall_612658
proc url_ListHostedZonesByName_613964(protocol: Scheme; host: string; base: string;
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

proc validate_ListHostedZonesByName_613963(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   dnsname: JString
  ##          : (Optional) For your first request to <code>ListHostedZonesByName</code>, include the <code>dnsname</code> parameter only if you want to specify the name of the first hosted zone in the response. If you don't include the <code>dnsname</code> parameter, Amazon Route 53 returns all of the hosted zones that were created by the current AWS account, in ASCII order. For subsequent requests, include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For <code>dnsname</code>, specify the value of <code>NextDNSName</code> from the previous response.
  ##   maxitems: JString
  ##           : The maximum number of hosted zones to be included in the response body for this request. If you have more than <code>maxitems</code> hosted zones, then the value of the <code>IsTruncated</code> element in the response is true, and the values of <code>NextDNSName</code> and <code>NextHostedZoneId</code> specify the first hosted zone in the next group of <code>maxitems</code> hosted zones. 
  ##   hostedzoneid: JString
  ##               : <p>(Optional) For your first request to <code>ListHostedZonesByName</code>, do not include the <code>hostedzoneid</code> parameter.</p> <p>If you have more hosted zones than the value of <code>maxitems</code>, <code>ListHostedZonesByName</code> returns only the first <code>maxitems</code> hosted zones. To get the next group of <code>maxitems</code> hosted zones, submit another request to <code>ListHostedZonesByName</code> and include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For the value of <code>hostedzoneid</code>, specify the value of the <code>NextHostedZoneId</code> element from the previous response.</p>
  section = newJObject()
  var valid_613965 = query.getOrDefault("dnsname")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "dnsname", valid_613965
  var valid_613966 = query.getOrDefault("maxitems")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "maxitems", valid_613966
  var valid_613967 = query.getOrDefault("hostedzoneid")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "hostedzoneid", valid_613967
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
  var valid_613968 = header.getOrDefault("X-Amz-Signature")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Signature", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Content-Sha256", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Date")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Date", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-Credential")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-Credential", valid_613971
  var valid_613972 = header.getOrDefault("X-Amz-Security-Token")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "X-Amz-Security-Token", valid_613972
  var valid_613973 = header.getOrDefault("X-Amz-Algorithm")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-Algorithm", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-SignedHeaders", valid_613974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613975: Call_ListHostedZonesByName_613962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ## 
  let valid = call_613975.validator(path, query, header, formData, body)
  let scheme = call_613975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613975.url(scheme.get, call_613975.host, call_613975.base,
                         call_613975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613975, url, valid)

proc call*(call_613976: Call_ListHostedZonesByName_613962; dnsname: string = "";
          maxitems: string = ""; hostedzoneid: string = ""): Recallable =
  ## listHostedZonesByName
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ##   dnsname: string
  ##          : (Optional) For your first request to <code>ListHostedZonesByName</code>, include the <code>dnsname</code> parameter only if you want to specify the name of the first hosted zone in the response. If you don't include the <code>dnsname</code> parameter, Amazon Route 53 returns all of the hosted zones that were created by the current AWS account, in ASCII order. For subsequent requests, include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For <code>dnsname</code>, specify the value of <code>NextDNSName</code> from the previous response.
  ##   maxitems: string
  ##           : The maximum number of hosted zones to be included in the response body for this request. If you have more than <code>maxitems</code> hosted zones, then the value of the <code>IsTruncated</code> element in the response is true, and the values of <code>NextDNSName</code> and <code>NextHostedZoneId</code> specify the first hosted zone in the next group of <code>maxitems</code> hosted zones. 
  ##   hostedzoneid: string
  ##               : <p>(Optional) For your first request to <code>ListHostedZonesByName</code>, do not include the <code>hostedzoneid</code> parameter.</p> <p>If you have more hosted zones than the value of <code>maxitems</code>, <code>ListHostedZonesByName</code> returns only the first <code>maxitems</code> hosted zones. To get the next group of <code>maxitems</code> hosted zones, submit another request to <code>ListHostedZonesByName</code> and include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For the value of <code>hostedzoneid</code>, specify the value of the <code>NextHostedZoneId</code> element from the previous response.</p>
  var query_613977 = newJObject()
  add(query_613977, "dnsname", newJString(dnsname))
  add(query_613977, "maxitems", newJString(maxitems))
  add(query_613977, "hostedzoneid", newJString(hostedzoneid))
  result = call_613976.call(nil, query_613977, nil, nil, nil)

var listHostedZonesByName* = Call_ListHostedZonesByName_613962(
    name: "listHostedZonesByName", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonesbyname",
    validator: validate_ListHostedZonesByName_613963, base: "/",
    url: url_ListHostedZonesByName_613964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceRecordSets_613978 = ref object of OpenApiRestCall_612658
proc url_ListResourceRecordSets_613980(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/rrset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResourceRecordSets_613979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to list.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613981 = path.getOrDefault("Id")
  valid_613981 = validateParameter(valid_613981, JString, required = true,
                                 default = nil)
  if valid_613981 != nil:
    section.add "Id", valid_613981
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   type: JString
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: JString
  ##                  : Pagination token
  ##   StartRecordIdentifier: JString
  ##                        : Pagination token
  ##   StartRecordType: JString
  ##                  : Pagination token
  ##   identifier: JString
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  section = newJObject()
  var valid_613982 = query.getOrDefault("name")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "name", valid_613982
  var valid_613983 = query.getOrDefault("MaxItems")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "MaxItems", valid_613983
  var valid_613984 = query.getOrDefault("type")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = newJString("SOA"))
  if valid_613984 != nil:
    section.add "type", valid_613984
  var valid_613985 = query.getOrDefault("maxitems")
  valid_613985 = validateParameter(valid_613985, JString, required = false,
                                 default = nil)
  if valid_613985 != nil:
    section.add "maxitems", valid_613985
  var valid_613986 = query.getOrDefault("StartRecordName")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "StartRecordName", valid_613986
  var valid_613987 = query.getOrDefault("StartRecordIdentifier")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "StartRecordIdentifier", valid_613987
  var valid_613988 = query.getOrDefault("StartRecordType")
  valid_613988 = validateParameter(valid_613988, JString, required = false,
                                 default = nil)
  if valid_613988 != nil:
    section.add "StartRecordType", valid_613988
  var valid_613989 = query.getOrDefault("identifier")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "identifier", valid_613989
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
  var valid_613990 = header.getOrDefault("X-Amz-Signature")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Signature", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Content-Sha256", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Date")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Date", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Credential")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Credential", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Security-Token")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Security-Token", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Algorithm")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Algorithm", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-SignedHeaders", valid_613996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613997: Call_ListResourceRecordSets_613978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ## 
  let valid = call_613997.validator(path, query, header, formData, body)
  let scheme = call_613997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613997.url(scheme.get, call_613997.host, call_613997.base,
                         call_613997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613997, url, valid)

proc call*(call_613998: Call_ListResourceRecordSets_613978; Id: string;
          name: string = ""; MaxItems: string = ""; `type`: string = "SOA";
          maxitems: string = ""; StartRecordName: string = "";
          StartRecordIdentifier: string = ""; StartRecordType: string = "";
          identifier: string = ""): Recallable =
  ## listResourceRecordSets
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ##   name: string
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: string
  ##           : Pagination limit
  ##   type: string
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: string
  ##                  : Pagination token
  ##   StartRecordIdentifier: string
  ##                        : Pagination token
  ##   StartRecordType: string
  ##                  : Pagination token
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to list.
  ##   identifier: string
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  var path_613999 = newJObject()
  var query_614000 = newJObject()
  add(query_614000, "name", newJString(name))
  add(query_614000, "MaxItems", newJString(MaxItems))
  add(query_614000, "type", newJString(`type`))
  add(query_614000, "maxitems", newJString(maxitems))
  add(query_614000, "StartRecordName", newJString(StartRecordName))
  add(query_614000, "StartRecordIdentifier", newJString(StartRecordIdentifier))
  add(query_614000, "StartRecordType", newJString(StartRecordType))
  add(path_613999, "Id", newJString(Id))
  add(query_614000, "identifier", newJString(identifier))
  result = call_613998.call(path_613999, query_614000, nil, nil, nil)

var listResourceRecordSets* = Call_ListResourceRecordSets_613978(
    name: "listResourceRecordSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset",
    validator: validate_ListResourceRecordSets_613979, base: "/",
    url: url_ListResourceRecordSets_613980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResources_614001 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResources_614003(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResources_614002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resources.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  var valid_614004 = path.getOrDefault("ResourceType")
  valid_614004 = validateParameter(valid_614004, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_614004 != nil:
    section.add "ResourceType", valid_614004
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
  var valid_614005 = header.getOrDefault("X-Amz-Signature")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Signature", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Content-Sha256", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-Date")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Date", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Credential")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Credential", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Security-Token")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Security-Token", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Algorithm")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Algorithm", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-SignedHeaders", valid_614011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614013: Call_ListTagsForResources_614001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_614013.validator(path, query, header, formData, body)
  let scheme = call_614013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614013.url(scheme.get, call_614013.host, call_614013.base,
                         call_614013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614013, url, valid)

proc call*(call_614014: Call_ListTagsForResources_614001; body: JsonNode;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResources
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceType: string (required)
  ##               : <p>The type of the resources.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   body: JObject (required)
  var path_614015 = newJObject()
  var body_614016 = newJObject()
  add(path_614015, "ResourceType", newJString(ResourceType))
  if body != nil:
    body_614016 = body
  result = call_614014.call(path_614015, nil, nil, nil, body_614016)

var listTagsForResources* = Call_ListTagsForResources_614001(
    name: "listTagsForResources", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/tags/{ResourceType}",
    validator: validate_ListTagsForResources_614002, base: "/",
    url: url_ListTagsForResources_614003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicies_614017 = ref object of OpenApiRestCall_612658
proc url_ListTrafficPolicies_614019(protocol: Scheme; host: string; base: string;
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

proc validate_ListTrafficPolicies_614018(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxitems: JString
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  ##   trafficpolicyid: JString
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  section = newJObject()
  var valid_614020 = query.getOrDefault("maxitems")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "maxitems", valid_614020
  var valid_614021 = query.getOrDefault("trafficpolicyid")
  valid_614021 = validateParameter(valid_614021, JString, required = false,
                                 default = nil)
  if valid_614021 != nil:
    section.add "trafficpolicyid", valid_614021
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
  var valid_614022 = header.getOrDefault("X-Amz-Signature")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-Signature", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Content-Sha256", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Date")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Date", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Credential")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Credential", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Security-Token")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Security-Token", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Algorithm")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Algorithm", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-SignedHeaders", valid_614028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614029: Call_ListTrafficPolicies_614017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  let valid = call_614029.validator(path, query, header, formData, body)
  let scheme = call_614029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614029.url(scheme.get, call_614029.host, call_614029.base,
                         call_614029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614029, url, valid)

proc call*(call_614030: Call_ListTrafficPolicies_614017; maxitems: string = "";
          trafficpolicyid: string = ""): Recallable =
  ## listTrafficPolicies
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ##   maxitems: string
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  ##   trafficpolicyid: string
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  var query_614031 = newJObject()
  add(query_614031, "maxitems", newJString(maxitems))
  add(query_614031, "trafficpolicyid", newJString(trafficpolicyid))
  result = call_614030.call(nil, query_614031, nil, nil, nil)

var listTrafficPolicies* = Call_ListTrafficPolicies_614017(
    name: "listTrafficPolicies", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicies",
    validator: validate_ListTrafficPolicies_614018, base: "/",
    url: url_ListTrafficPolicies_614019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstances_614032 = ref object of OpenApiRestCall_612658
proc url_ListTrafficPolicyInstances_614034(protocol: Scheme; host: string;
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

proc validate_ListTrafficPolicyInstances_614033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_614035 = query.getOrDefault("trafficpolicyinstancetype")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = newJString("SOA"))
  if valid_614035 != nil:
    section.add "trafficpolicyinstancetype", valid_614035
  var valid_614036 = query.getOrDefault("maxitems")
  valid_614036 = validateParameter(valid_614036, JString, required = false,
                                 default = nil)
  if valid_614036 != nil:
    section.add "maxitems", valid_614036
  var valid_614037 = query.getOrDefault("trafficpolicyinstancename")
  valid_614037 = validateParameter(valid_614037, JString, required = false,
                                 default = nil)
  if valid_614037 != nil:
    section.add "trafficpolicyinstancename", valid_614037
  var valid_614038 = query.getOrDefault("hostedzoneid")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "hostedzoneid", valid_614038
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
  var valid_614039 = header.getOrDefault("X-Amz-Signature")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Signature", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-Content-Sha256", valid_614040
  var valid_614041 = header.getOrDefault("X-Amz-Date")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Date", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Credential")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Credential", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Security-Token")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Security-Token", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-Algorithm")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Algorithm", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-SignedHeaders", valid_614045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614046: Call_ListTrafficPolicyInstances_614032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_614046.validator(path, query, header, formData, body)
  let scheme = call_614046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614046.url(scheme.get, call_614046.host, call_614046.base,
                         call_614046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614046, url, valid)

proc call*(call_614047: Call_ListTrafficPolicyInstances_614032;
          trafficpolicyinstancetype: string = "SOA"; maxitems: string = "";
          trafficpolicyinstancename: string = ""; hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstances
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_614048 = newJObject()
  add(query_614048, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_614048, "maxitems", newJString(maxitems))
  add(query_614048, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_614048, "hostedzoneid", newJString(hostedzoneid))
  result = call_614047.call(nil, query_614048, nil, nil, nil)

var listTrafficPolicyInstances* = Call_ListTrafficPolicyInstances_614032(
    name: "listTrafficPolicyInstances", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstances",
    validator: validate_ListTrafficPolicyInstances_614033, base: "/",
    url: url_ListTrafficPolicyInstances_614034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByHostedZone_614049 = ref object of OpenApiRestCall_612658
proc url_ListTrafficPolicyInstancesByHostedZone_614051(protocol: Scheme;
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

proc validate_ListTrafficPolicyInstancesByHostedZone_614050(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: JString (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_614052 = query.getOrDefault("trafficpolicyinstancetype")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = newJString("SOA"))
  if valid_614052 != nil:
    section.add "trafficpolicyinstancetype", valid_614052
  var valid_614053 = query.getOrDefault("maxitems")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "maxitems", valid_614053
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_614054 = query.getOrDefault("id")
  valid_614054 = validateParameter(valid_614054, JString, required = true,
                                 default = nil)
  if valid_614054 != nil:
    section.add "id", valid_614054
  var valid_614055 = query.getOrDefault("trafficpolicyinstancename")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "trafficpolicyinstancename", valid_614055
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
  var valid_614056 = header.getOrDefault("X-Amz-Signature")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Signature", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-Content-Sha256", valid_614057
  var valid_614058 = header.getOrDefault("X-Amz-Date")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-Date", valid_614058
  var valid_614059 = header.getOrDefault("X-Amz-Credential")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "X-Amz-Credential", valid_614059
  var valid_614060 = header.getOrDefault("X-Amz-Security-Token")
  valid_614060 = validateParameter(valid_614060, JString, required = false,
                                 default = nil)
  if valid_614060 != nil:
    section.add "X-Amz-Security-Token", valid_614060
  var valid_614061 = header.getOrDefault("X-Amz-Algorithm")
  valid_614061 = validateParameter(valid_614061, JString, required = false,
                                 default = nil)
  if valid_614061 != nil:
    section.add "X-Amz-Algorithm", valid_614061
  var valid_614062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614062 = validateParameter(valid_614062, JString, required = false,
                                 default = nil)
  if valid_614062 != nil:
    section.add "X-Amz-SignedHeaders", valid_614062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614063: Call_ListTrafficPolicyInstancesByHostedZone_614049;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_614063.validator(path, query, header, formData, body)
  let scheme = call_614063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614063.url(scheme.get, call_614063.host, call_614063.base,
                         call_614063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614063, url, valid)

proc call*(call_614064: Call_ListTrafficPolicyInstancesByHostedZone_614049;
          id: string; trafficpolicyinstancetype: string = "SOA";
          maxitems: string = ""; trafficpolicyinstancename: string = ""): Recallable =
  ## listTrafficPolicyInstancesByHostedZone
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: string (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_614065 = newJObject()
  add(query_614065, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_614065, "maxitems", newJString(maxitems))
  add(query_614065, "id", newJString(id))
  add(query_614065, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  result = call_614064.call(nil, query_614065, nil, nil, nil)

var listTrafficPolicyInstancesByHostedZone* = Call_ListTrafficPolicyInstancesByHostedZone_614049(
    name: "listTrafficPolicyInstancesByHostedZone", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/hostedzone#id",
    validator: validate_ListTrafficPolicyInstancesByHostedZone_614050, base: "/",
    url: url_ListTrafficPolicyInstancesByHostedZone_614051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByPolicy_614066 = ref object of OpenApiRestCall_612658
proc url_ListTrafficPolicyInstancesByPolicy_614068(protocol: Scheme; host: string;
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

proc validate_ListTrafficPolicyInstancesByPolicy_614067(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: JInt (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: JString (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_614069 = query.getOrDefault("trafficpolicyinstancetype")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = newJString("SOA"))
  if valid_614069 != nil:
    section.add "trafficpolicyinstancetype", valid_614069
  assert query != nil, "query argument is necessary due to required `version` field"
  var valid_614070 = query.getOrDefault("version")
  valid_614070 = validateParameter(valid_614070, JInt, required = true, default = nil)
  if valid_614070 != nil:
    section.add "version", valid_614070
  var valid_614071 = query.getOrDefault("maxitems")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "maxitems", valid_614071
  var valid_614072 = query.getOrDefault("id")
  valid_614072 = validateParameter(valid_614072, JString, required = true,
                                 default = nil)
  if valid_614072 != nil:
    section.add "id", valid_614072
  var valid_614073 = query.getOrDefault("trafficpolicyinstancename")
  valid_614073 = validateParameter(valid_614073, JString, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "trafficpolicyinstancename", valid_614073
  var valid_614074 = query.getOrDefault("hostedzoneid")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "hostedzoneid", valid_614074
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
  var valid_614075 = header.getOrDefault("X-Amz-Signature")
  valid_614075 = validateParameter(valid_614075, JString, required = false,
                                 default = nil)
  if valid_614075 != nil:
    section.add "X-Amz-Signature", valid_614075
  var valid_614076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614076 = validateParameter(valid_614076, JString, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "X-Amz-Content-Sha256", valid_614076
  var valid_614077 = header.getOrDefault("X-Amz-Date")
  valid_614077 = validateParameter(valid_614077, JString, required = false,
                                 default = nil)
  if valid_614077 != nil:
    section.add "X-Amz-Date", valid_614077
  var valid_614078 = header.getOrDefault("X-Amz-Credential")
  valid_614078 = validateParameter(valid_614078, JString, required = false,
                                 default = nil)
  if valid_614078 != nil:
    section.add "X-Amz-Credential", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-Security-Token")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-Security-Token", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-Algorithm")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-Algorithm", valid_614080
  var valid_614081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "X-Amz-SignedHeaders", valid_614081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614082: Call_ListTrafficPolicyInstancesByPolicy_614066;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_614082.validator(path, query, header, formData, body)
  let scheme = call_614082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614082.url(scheme.get, call_614082.host, call_614082.base,
                         call_614082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614082, url, valid)

proc call*(call_614083: Call_ListTrafficPolicyInstancesByPolicy_614066;
          version: int; id: string; trafficpolicyinstancetype: string = "SOA";
          maxitems: string = ""; trafficpolicyinstancename: string = "";
          hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstancesByPolicy
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: int (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: string (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_614084 = newJObject()
  add(query_614084, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_614084, "version", newJInt(version))
  add(query_614084, "maxitems", newJString(maxitems))
  add(query_614084, "id", newJString(id))
  add(query_614084, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_614084, "hostedzoneid", newJString(hostedzoneid))
  result = call_614083.call(nil, query_614084, nil, nil, nil)

var listTrafficPolicyInstancesByPolicy* = Call_ListTrafficPolicyInstancesByPolicy_614066(
    name: "listTrafficPolicyInstancesByPolicy", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/trafficpolicy#id&version",
    validator: validate_ListTrafficPolicyInstancesByPolicy_614067, base: "/",
    url: url_ListTrafficPolicyInstancesByPolicy_614068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyVersions_614085 = ref object of OpenApiRestCall_612658
proc url_ListTrafficPolicyVersions_614087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicies/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTrafficPolicyVersions_614086(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Specify the value of <code>Id</code> of the traffic policy for which you want to list all versions.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_614088 = path.getOrDefault("Id")
  valid_614088 = validateParameter(valid_614088, JString, required = true,
                                 default = nil)
  if valid_614088 != nil:
    section.add "Id", valid_614088
  result.add "path", section
  ## parameters in `query` object:
  ##   maxitems: JString
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  ##   trafficpolicyversion: JString
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  section = newJObject()
  var valid_614089 = query.getOrDefault("maxitems")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "maxitems", valid_614089
  var valid_614090 = query.getOrDefault("trafficpolicyversion")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "trafficpolicyversion", valid_614090
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
  var valid_614091 = header.getOrDefault("X-Amz-Signature")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Signature", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Content-Sha256", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Date")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Date", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-Credential")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-Credential", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-Security-Token")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-Security-Token", valid_614095
  var valid_614096 = header.getOrDefault("X-Amz-Algorithm")
  valid_614096 = validateParameter(valid_614096, JString, required = false,
                                 default = nil)
  if valid_614096 != nil:
    section.add "X-Amz-Algorithm", valid_614096
  var valid_614097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614097 = validateParameter(valid_614097, JString, required = false,
                                 default = nil)
  if valid_614097 != nil:
    section.add "X-Amz-SignedHeaders", valid_614097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614098: Call_ListTrafficPolicyVersions_614085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ## 
  let valid = call_614098.validator(path, query, header, formData, body)
  let scheme = call_614098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614098.url(scheme.get, call_614098.host, call_614098.base,
                         call_614098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614098, url, valid)

proc call*(call_614099: Call_ListTrafficPolicyVersions_614085; Id: string;
          maxitems: string = ""; trafficpolicyversion: string = ""): Recallable =
  ## listTrafficPolicyVersions
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  ##   trafficpolicyversion: string
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  ##   Id: string (required)
  ##     : Specify the value of <code>Id</code> of the traffic policy for which you want to list all versions.
  var path_614100 = newJObject()
  var query_614101 = newJObject()
  add(query_614101, "maxitems", newJString(maxitems))
  add(query_614101, "trafficpolicyversion", newJString(trafficpolicyversion))
  add(path_614100, "Id", newJString(Id))
  result = call_614099.call(path_614100, query_614101, nil, nil, nil)

var listTrafficPolicyVersions* = Call_ListTrafficPolicyVersions_614085(
    name: "listTrafficPolicyVersions", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicies/{Id}/versions",
    validator: validate_ListTrafficPolicyVersions_614086, base: "/",
    url: url_ListTrafficPolicyVersions_614087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestDNSAnswer_614102 = ref object of OpenApiRestCall_612658
proc url_TestDNSAnswer_614104(protocol: Scheme; host: string; base: string;
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

proc validate_TestDNSAnswer_614103(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   edns0clientsubnetip: JString
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   edns0clientsubnetmask: JString
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   recordname: JString (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   resolverip: JString
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordtype: JString (required)
  ##             : The type of the resource record set.
  ##   hostedzoneid: JString (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  section = newJObject()
  var valid_614105 = query.getOrDefault("edns0clientsubnetip")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "edns0clientsubnetip", valid_614105
  var valid_614106 = query.getOrDefault("edns0clientsubnetmask")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "edns0clientsubnetmask", valid_614106
  assert query != nil,
        "query argument is necessary due to required `recordname` field"
  var valid_614107 = query.getOrDefault("recordname")
  valid_614107 = validateParameter(valid_614107, JString, required = true,
                                 default = nil)
  if valid_614107 != nil:
    section.add "recordname", valid_614107
  var valid_614108 = query.getOrDefault("resolverip")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "resolverip", valid_614108
  var valid_614109 = query.getOrDefault("recordtype")
  valid_614109 = validateParameter(valid_614109, JString, required = true,
                                 default = newJString("SOA"))
  if valid_614109 != nil:
    section.add "recordtype", valid_614109
  var valid_614110 = query.getOrDefault("hostedzoneid")
  valid_614110 = validateParameter(valid_614110, JString, required = true,
                                 default = nil)
  if valid_614110 != nil:
    section.add "hostedzoneid", valid_614110
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
  var valid_614111 = header.getOrDefault("X-Amz-Signature")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "X-Amz-Signature", valid_614111
  var valid_614112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "X-Amz-Content-Sha256", valid_614112
  var valid_614113 = header.getOrDefault("X-Amz-Date")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "X-Amz-Date", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Credential")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Credential", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-Security-Token")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-Security-Token", valid_614115
  var valid_614116 = header.getOrDefault("X-Amz-Algorithm")
  valid_614116 = validateParameter(valid_614116, JString, required = false,
                                 default = nil)
  if valid_614116 != nil:
    section.add "X-Amz-Algorithm", valid_614116
  var valid_614117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614117 = validateParameter(valid_614117, JString, required = false,
                                 default = nil)
  if valid_614117 != nil:
    section.add "X-Amz-SignedHeaders", valid_614117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614118: Call_TestDNSAnswer_614102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  let valid = call_614118.validator(path, query, header, formData, body)
  let scheme = call_614118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614118.url(scheme.get, call_614118.host, call_614118.base,
                         call_614118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614118, url, valid)

proc call*(call_614119: Call_TestDNSAnswer_614102; recordname: string;
          hostedzoneid: string; edns0clientsubnetip: string = "";
          edns0clientsubnetmask: string = ""; resolverip: string = "";
          recordtype: string = "SOA"): Recallable =
  ## testDNSAnswer
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ##   edns0clientsubnetip: string
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   edns0clientsubnetmask: string
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   recordname: string (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   resolverip: string
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordtype: string (required)
  ##             : The type of the resource record set.
  ##   hostedzoneid: string (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  var query_614120 = newJObject()
  add(query_614120, "edns0clientsubnetip", newJString(edns0clientsubnetip))
  add(query_614120, "edns0clientsubnetmask", newJString(edns0clientsubnetmask))
  add(query_614120, "recordname", newJString(recordname))
  add(query_614120, "resolverip", newJString(resolverip))
  add(query_614120, "recordtype", newJString(recordtype))
  add(query_614120, "hostedzoneid", newJString(hostedzoneid))
  result = call_614119.call(nil, query_614120, nil, nil, nil)

var testDNSAnswer* = Call_TestDNSAnswer_614102(name: "testDNSAnswer",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/testdnsanswer#hostedzoneid&recordname&recordtype",
    validator: validate_TestDNSAnswer_614103, base: "/", url: url_TestDNSAnswer_614104,
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
